# aws configure

# name prefix
variable "name_prefix" {
  type        = string
  default     = "test-dzg"
  description = "Name prefix"
}

# aws region
variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS Region"
}

variable "aws_azs" {
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  description = "AWS Availability Zones"
}
  
variable "aws_vpc_cidr" {
  type        = string
  default     = "172.20.0.0/16"
  description = "AWS VPC CIDR"
}

variable "aws_private_subnets" {
  type        = list(string)
  default     = ["172.20.1.0/24", "172.20.2.0/24", "172.20.3.0/24"]
  description = "AWS Private Subnets"
}

variable "aws_public_subnets" {
  type        = list(string)
  default     = ["172.20.101.0/24", "172.20.102.0/24", "172.20.103.0/24"]
  description = "AWS Public Subnets"
}

## servers spec

variable "bastion_instance_type" {
  type    = string
  default = "t2.medium"
}

## servers disk 

variable "root_disk_size" {
  type    = number
  default = 300
}


## tags 

variable "tags" {
    type = map(string)
    default = {
        "Owner" = "hoge@fuga.com",
        "Project" = "hogehoge",
        "Environment" = "test",
    }
    description = "The tags to be added to the resources"
}

## bastion allow ssh from
variable "bastion_allow_ssh_from" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

