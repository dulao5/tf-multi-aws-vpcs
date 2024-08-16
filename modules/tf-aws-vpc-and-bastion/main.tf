# vpc settings


# default security group
resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# using terraform aws vpc module
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.name_prefix}-vpc"

  cidr = var.aws_vpc_cidr

  azs             = var.aws_azs
  private_subnets = var.aws_private_subnets
  public_subnets  = var.aws_public_subnets

  # TiDB instances located in private subnets typically have reduced need for external network access. 
  # Both "tiup cluster deploy" and "tiup check -apply" commands do not necessitate external network access. 
  # Consequently, the deactivation of the nat-gateway could result in cost savings.
  # 
  # In cases where nat-gateway usage is preferred, 
  # "single_nat_gateway=true" can be employed, 
  # as intermittent access to the nat-gateway does not mandate its high availability.
  # enable_nat_gateway = false
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags

  /*
  default_security_group_ingress = [
    // all to tidb port 4000 in same security group
    {
      from_port         = 0
      to_port           = 4000
      protocol         = "tcp"
      source_security_groups = module.vpc.default_security_group_id
    }
  ]
  default_security_group_egress = [
    // all to internet
    {
      from_port         = 0
      to_port           = 0
      protocol         = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]*/

}

module "security_group_bastion" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name_prefix}-bastion"
  description = "bastion(tiup) security group (allow 22 port)"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.bastion_allow_ssh_from
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

# key pair settings

# using terraform aws key pair module
# https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws/latest
module "key_pair_tidb_bastion" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name   = "${var.name_prefix}-${var.aws_region}-bastion"
  create_private_key = true
}
module "key_pair_tidb_internal" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name   = "${var.name_prefix}-${var.aws_region}-internal"
  create_private_key = true
}

# ami settings

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# EC2 Module

# bastion ec2 instance
module "ec2_bastion"{
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name_prefix}-bastion"

  ami                         = data.aws_ami.amazon_linux.id
  //ami                         = "ami-0dfb37a96b613c174" # sysbench-amazon-linux-2023	
  instance_type               = var.bastion_instance_type
  availability_zone           = var.aws_azs[0]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_bastion.security_group_id, module.vpc.default_security_group_id]
  associate_public_ip_address = true

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]

  # key pair
  key_name = module.key_pair_tidb_bastion.key_pair_name

  # user data : init ~ec2-user/.ssh for login to internal tidb instances
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p ~ec2-user/.ssh
    echo "${module.key_pair_tidb_internal.private_key_openssh}" > ~ec2-user/.ssh/id_rsa
    chmod 600 ~ec2-user/.ssh/id_rsa
    chown -R ec2-user:ec2-user ~ec2-user/.ssh
    sudo dnf check-release-update
    sudo dnf install -y mariadb105
  EOF
}


resource "local_file" "connect_script" {
  content = templatefile("${path.module}/files/connect.sh.tpl", {
    bastion_public_ip: module.ec2_bastion.public_ip,
    name_prefix: var.name_prefix
  })
  filename = "${path.root}/connect-to-${var.name_prefix}-vpc.sh"
  file_permission = "0755"
}

resource "local_file" "private_key" {
  content = "${module.key_pair_tidb_bastion.private_key_pem}"
  filename = "${path.root}/private_key_openssh_${var.name_prefix}-vpc"
  file_permission = "0600"
}

resource "null_resource" "bastion-inventory" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${module.key_pair_tidb_bastion.private_key_openssh}"
    host        = element(module.ec2_bastion.*.public_ip, 0)
  }

  provisioner "remote-exec" {
    inline = [
      "curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh"
    ]
  }
}

