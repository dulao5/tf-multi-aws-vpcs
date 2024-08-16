output "vpc_name" {
  value = "${module.vpc.name}"
}
output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}
output "vpc_cidr" {
  value = "${module.vpc.vpc_cidr_block}"
}
output "private_subnet_ids" {
  value = "${join(" ", module.vpc.private_subnets)}"
}
output "public_subnet_ids" {
  value = "${join(" ", module.vpc.public_subnets)}"
}
output "bastion_ip" {
  value = "${join(" ", module.ec2_bastion.*.public_ip)}"
}


# tidb_bastion keypair private key
output "tidb_bastion_keypair_private_key" {
  value = "${module.key_pair_tidb_bastion.private_key_pem}"
  //sensitive = true
}

