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
import json
from argparse import Action, ArgumentTypeError
import boto3
class AfiAction(Action):
    def __call__(self, parser, namespace, agfi, option_string=None, nargs=None):
        d = self.validate(agfi[0])

        setattr(namespace, self.dest, d)

    def validate(self, agfi):
        ec2 = boto3.resource('ec2')
        cli = boto3.client('ec2')
        rsp = cli.describe_fpga_images(
            DryRun=False,
            FpgaImageIds=['afi-044f5fc0792dfe575'],
            Filters=[
                {
            'Name': 'fpga-image-global-id',
                    'Values': [
                        'agfi-087dad34c50a15366',
                    ]
                },
            ],
            MaxResults=5
        )['FpgaImages']

        if(len(rsp) == 0):
            raise ValueError('Error! AFI {} not found'.format(agfi))

        return {'AGFI' : rsp[0]['FpgaImageGlobalId'],
                'AFI'  : rsp[0]['FpgaImageId']}


