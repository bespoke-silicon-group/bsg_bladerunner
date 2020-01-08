# Build Scripts

The scripts in this directory build AMIs from a host server. These scripts are
split into two parts: 

## build.py

build.py is responsible for the overall process of building an AMI.The first
script launches an instance, loads the bootstrap script, waits for the image to
stop itself, and then generates the AMI from that stopped instance.

build.py takes in repo@commit_id arguments with -r option (order is arbitrary): 
1. bsg_f1@commit_id: The commit ID of bsg_f1 repo in git	(master is "29c861d86e5a25e3a6c56a5e79d196e2d706702f" on 02-18-2019)
2. bsg_manycore@commit_id: The commit ID of bsg_manycore repo in git (master is "c0e4c8a03a2e853f8fdcdddd84ec9db1ebd3edcb" on 02-18-2019)
3. bsg_ip_cores@commit_id: The commit ID of bsg_ip_cores repo in git (master is "088b8f573c6108c3716a770e7cba0029fb611578" on 02-18-2019)
Commit IDs should be at least 7 characters and in hex format 
example run: python3 ./build.py -r bsg_f1@29c861d86e5a25e3a6c56a5e79d196e2d706702f bsg_manycore@c0e4c8a03a2e853f8fdcdddd84ec9db1ebd3edcb bsg_ip_cores@088b8f573c6108c3716a770e7cba0029fb611578


The generated AMI is named with a unique timestamp value in the name: 
"BSG AMI <Year><Month><Day>-<Hour><Minute><Second>". (This may change in the
future to include the git commit ID)

build.py uses the [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
library to interact with the AWS Console.

## bootstrap.sh

bootstrap.sh is a UserData shell script that is run by the instance on first
boot. It is passed as a string and run with root permissions.

For more information about UserData can be found
[here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html).



