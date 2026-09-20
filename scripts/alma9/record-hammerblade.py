#!/usr/bin/env python3
"""Record source identities and the exact local tools, models, and test outputs.

Run after validation, with a checkout and its machine directory name. A record
describes what was tested; it does not authorize reuse after inputs change.
"""
import datetime
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


if len(sys.argv) != 3:
    sys.exit("Usage: record-hammerblade.py CHECKOUT MACHINE_NAME")
root = Path(sys.argv[1]).resolve(strict=True)
replicant = root / "bsg_replicant"
machine = replicant / "machines" / sys.argv[2]
if machine.parent != replicant / "machines" or not machine.is_dir():
    sys.exit("Unknown machine directory")
toolchain = root / "bsg_manycore/software/riscv-tools/riscv-gnu-toolchain"
repos = {root, toolchain}
for parent in (root, toolchain):
    for line in output("git", "-C", str(parent), "submodule", "status", "--recursive").splitlines():
        if line[0] != "-":
            repos.add(parent / line[1:].split()[1])
sources = {}
for repo in sorted(repos):
    changes = subprocess.check_output(["git", "-C", str(repo), "diff", "HEAD", "--binary"])
    sources[str(repo.relative_to(root))] = {
        "commit": output("git", "-C", str(repo), "rev-parse", "HEAD"),
        "status": output("git", "-C", str(repo), "status", "--short"),
        "tracked_diff_sha256": hashlib.sha256(changes).hexdigest(),
    }

files = set()
files.update(p for p in machine.iterdir() if p.is_file())
for mode in ("exec", "profile", "trace", "debug"):
    directory = machine / "bigblade-verilator" / mode
    files.update(directory.glob("simsc"))
    files.update(directory.glob("*__verFiles.dat"))
    files.update(directory.glob(".verilator*config"))
for directory in [replicant / "libraries/platforms/bigblade-verilator"] + [
    replicant / "libraries/features" / feature / "simulation"
    for feature in ("dma", "tracer", "pc_histogram")
]:
    files.update(directory.glob("*.so*"))
    files.update(directory.glob(".dramsim3*"))
    files.update(directory.glob(".verilator*config"))
files.add(root / "verilator/bin/verilator_bin")
prefix = root / "bsg_manycore/software/riscv-tools/riscv-install"
for filename in ("riscv32-unknown-elf-dramfs-gcc", "riscv32-unknown-elf-dramfs-g++", "riscv32-unknown-elf-dramfs-ld"):
    files.add(prefix / "bin" / filename)
files.update(prefix.rglob("libc.a"))
files.update(prefix.rglob("libgcc.a"))
files.update(prefix.rglob("cc1*"))
application = replicant / "examples/cuda/test_vec_add"
files.update(application.glob("*.riscv"))
files.update(application.glob("*.so"))
files.update(application.glob("*.log"))
files.update(application.glob("*stats.csv"))
benchmark = replicant / "examples/hb_hammerbench/apps/vector_add"
for pattern in ("tile-*/*.riscv", "tile-*/*.so", "tile-*/*.log", "tile-*/*stats.csv", "tile-*/parameters.mk", "tile-*/stats/manycore_stats.log"):
    files.update(benchmark.glob(pattern))
files.update((root / "build/kk6/logs").glob("*.log"))
files.update((root / "build/kk6").glob("*.txt"))
compilers = (root / "build/kk6/host-compilers.txt").read_text().splitlines()
if len(compilers) != 2:
    sys.exit("Invalid host compiler record")
record = {
    "recorded_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "checkout": str(root),
    "machine": machine.name,
    "platform": "bigblade-verilator",
    "verilator_threads": 1,
    "setup_bundle_sha256": {
        path.name: digest(path)
        for path in sorted(Path(__file__).resolve().parent.iterdir())
        if path.is_file() and (path.suffix in (".sh", ".py") or path.name == "hammerblade-python-requirements.txt")
    },
    "sources": sources,
    "host_compilers": {name: output(name, "--version").splitlines()[0] for name in compilers},
    "toolchain_host_gcc": output("/usr/bin/gcc", "--version").splitlines()[0],
    "host_tool_sha256": {
        name: digest(Path(name))
        for name in set(compilers + ["/usr/bin/gcc", "/usr/bin/g++", "/usr/bin/as", "/usr/bin/ld", "/usr/bin/make", "/usr/bin/python3"])
    },
    "host_packages": output("rpm", "-qa", "--qf", "%{NAME} %{VERSION}-%{RELEASE} %{ARCH}\n").splitlines(),
    "python_packages": output(str(root / "build/kk6/python/bin/python"), "-m", "pip", "--no-cache-dir", "--disable-pip-version-check", "freeze").splitlines(),
    "sha256": {str(path.relative_to(root)): digest(path) for path in sorted(files) if path.is_file()},
}
destination = root / "build/kk6/validation-record.json"
destination.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
print(destination)
