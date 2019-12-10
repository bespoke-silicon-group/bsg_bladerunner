#!/usr/bin/python3
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


# build.py is a script that builds an Amazon EC2 AMI with BSG tools/IP
# directories installed and configured. It uses the boto3 library to interact
# with the AWS console. The script launches an instance, passes a UserData
# script, waits for the instance to stop itself, and then creates an AMI.
import boto3
import datetime
import time
import argparse 
import os
import inspect
from functools import reduce
from ReleaseRepoAction import ReleaseRepoAction
from AfiAction import AfiAction
from VersionAction import VersionAction

parser = argparse.ArgumentParser(description='Build an AWS EC2 F1 FPGA Image')
parser.add_argument('Name', type=str, nargs=1,
                    help='Project Name for AMI')
parser.add_argument('Release', action=ReleaseRepoAction, nargs=1,
                    help='BSG Release repository for this build as: repo_name@commit_id')
parser.add_argument('AfiId', action=AfiAction, nargs=1,
                    default={"AmazonFpgaImageID":"Not-Specified-During-AMI-Build"},
                    help='JSON File Path with "FpgaImageId" and "FpgaImageGlobalId" defined')
parser.add_argument('ImageVersion', action=VersionAction, nargs=1,
                    help='Version number of the AMI')
parser.add_argument('-d', '--dryrun', action='store_const', const=True,
                    help='Process the arguments but do not launch an instance')

args = parser.parse_args()

# The timestamp is used in the instance name and the AMI name
timestamp = datetime.datetime.now().strftime('%Y/%m/%d-%H:%M:%S')
instance_name = 'v' + args.ImageVersion + ' ' + timestamp + '_image_build'
ami_name = 'BSG ' + args.Name[0] + ' v' + args.ImageVersion + ' AMI ' 
base_ami = 'ami-0217815815c960b75'
# The instance type is used to build the image - it does not need to match the
# final instance type (e.g. an F1 instance type)
instance_type = 't2.2xlarge'

# Connect to AWS Servicesn
ec2 = boto3.resource('ec2')
cli = boto3.client('ec2')

# Create a "waiter" to wait on the "Stopped" state
waiter = cli.get_waiter('instance_stopped')

# Open Userdata (bootstrap.init) and pass it the name of the current release repository
curscr = os.path.abspath(inspect.getfile(inspect.currentframe()))
curdir = os.path.dirname(curscr)
bootstrap_path = os.path.join(curdir, "bootstrap.init")

UserData = open(bootstrap_path,'r').read()
UserData = UserData.replace("$release_repo", args.Release["name"])
UserData = UserData.replace("$release_hash", args.Release["commit"])

if(args.dryrun):
    print(ami_name)
    print(UserData)
    exit(0)

# Create and launch an instance
instance = ec2.create_instances(
    ImageId=base_ami,
    InstanceType=instance_type,
    KeyName='cad-xor',
    SecurityGroupIds=['bsg_sg_xor_uswest2'],
        UserData=UserData,
        MinCount=1,
    MaxCount=1,
    TagSpecifications=[{'ResourceType':'instance',
                         'Tags':[{'Key':'Name',
                                  'Value':instance_name}]}],
    BlockDeviceMappings=[
        {
            'DeviceName': '/dev/sda1',
            'Ebs': {
                'DeleteOnTermination': True,
                'VolumeSize': 150,
            }
        },
    ])[0]

print('Generated Instance: ' + instance.id);

# This is necessary to give the instance some time to be registered
instance.wait_until_running()
print("Instance running. Waiting for instance to enter 'Stopped' state.")
waiter.wait(
    InstanceIds=[
        instance.id,
    ],
    WaiterConfig={
        'Delay': 60,
        'MaxAttempts': 180
    }
)
print('Instance configuration completed')

# Finally, generate the AMI 
ami = cli.create_image(InstanceId=instance.id, Name=ami_name, 
                       Description="BSG AMI with release repository {}@{}".format(args.Release["name"], args.Release["commit"]))
cli.create_tags(Resources=[ami['ImageId']],Tags=[{'Key':'Version','Value':args.ImageVersion},
                                                 {'Key':'Timestamp','Value':timestamp},
                                                 {'Key':'Project','Value':args.Name[0]}])
print('Creating AMI: ' + ami['ImageId'])
