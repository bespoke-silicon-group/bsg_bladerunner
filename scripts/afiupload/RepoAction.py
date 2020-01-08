# Copyright (c) 2019, University of Washington All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
# 
# Neither the name of the copyright holder nor the names of its contributors may
# be used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import os
import git
from git.exc import CacheError
from argparse import Action, ArgumentTypeError

class RepoAction(Action):
        def __call__(self, parser, namespace, repo_at_commit_id, option_string=None):
                build_dir = getattr(namespace, "BuildDirectory")
                if(build_dir) is None:
                        raise KeyError(("BuildDirectory argument not "+ 
                                       "specified! BuildDirectory must be "+
                                       "specified before -{}").format(self.dest))

                repo, commit, path= self.validate(build_dir, repo_at_commit_id[0])
                repo_ids = getattr(namespace, self.dest)
                if(repo_ids is None):
                        repo_ids = {}
                repo_ids[repo] = {"commit": commit, "path":path}
                setattr(namespace, self.dest, repo_ids)
        
        def validate(self, build_dir, repo):
                short = os.path.join(build_dir, repo)
                long = os.path.join(build_dir, repo)

                if os.path.isdir(short):
                        d = short
                elif os.path.isdir(long):
                        d = long
                else:
                        raise FileNotFoundError("Repo Directory not found!" +
                                                "Searched for {} and {}".format(short, long))

                r = git.Repo(d)
                i = r.index
                if len(i.diff(None)) != 0:
                        raise CacheError(f"Local {repo} repository differs " +
                                         "from remote. Have you committed " +
                                         "and pushed your changes?")

                sha = r.head.object.hexsha
                sha = sha[0:7]
                
                return (repo, sha, d)
