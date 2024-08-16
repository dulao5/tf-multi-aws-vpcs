provider "aws" {
  region = "us-west-2"
}

# multiple vpcs
module "vpcs" {
  source = "./modules/tf-aws-vpc-and-bastion"
  count = 40
  
  name_prefix = "ss-${count.index}"
  aws_region = "us-west-2"
  aws_azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  aws_vpc_cidr = "10.${count.index+21}.0.0/16"
  aws_private_subnets = ["10.${count.index+21}.1.0/24", "10.${count.index+21}.2.0/24", "10.${count.index+21}.3.0/24"]
  aws_public_subnets = ["10.${count.index+21}.21.0/24", "10.${count.index+21}.22.0/24", "10.${count.index+21}.23.0/24"]
  tags = {
        "Owner" = "zhigang.du@pingcap.com",
        "Project" = "SuperStudio",
        "Environment" = "test-${count.index}",
  }
}

output "vpc_names" {
  value = "${module.vpcs.*.vpc_name}"
}
output "vpc_ids" {
  value = "${module.vpcs.*.vpc_id}"
}

output "bastion_ips" {
  value = "${module.vpcs.*.bastion_ip}"
}

output "public_subnet_ids" {
  value = "${module.vpcs.*.public_subnet_ids}"
}

# tidb_bastion keypair private key
output "tidb_bastion_keypair_private_keys" {
  value = "${module.vpcs.*.tidb_bastion_keypair_private_key}"
  sensitive = true
}

