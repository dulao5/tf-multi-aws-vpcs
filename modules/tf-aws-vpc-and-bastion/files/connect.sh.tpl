#!/bin/sh 

## create private key
# 


ssh -i private_key_openssh_${name_prefix}-vpc ec2-user@${bastion_public_ip}

