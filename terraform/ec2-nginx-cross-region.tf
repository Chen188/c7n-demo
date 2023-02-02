# create 2 private ec2 instances, one in main vpc, another in secondary vpc.
locals {
  ami_filters = [{
    name   = "owner-alias"
    values = ["amazon"]
    }, {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
    }, {
    name   = "architecture"
    values = ["x86_64"]
    }, {
    name   = "virtualization-type"
    values = ["hvm"]
    }, {
    name   = "root-device-type"
    values = ["ebs"]
  }]

  # will need nat gw to access internet
  user_data = <<EOF
#!/bin/bash
echo "Install nginx"
amazon-linux-extras install -y nginx1
yum install jq -y
REGION=`curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region`
echo "Nginx: $REGION" > /usr/share/nginx/html/index.html
systemctl start nginx
systemctl enable nginx
EOF
}

data "aws_ami" "al2_x86_vpc_main" {
  most_recent = true
  dynamic "filter" {
    for_each = local.ami_filters

    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
  owners = ["amazon"]
}

data "aws_ami" "al2_x86_vpc_secondary" {
  provider    = aws.region_secondary
  most_recent = true
  dynamic "filter" {
    for_each = local.ami_filters

    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
  owners = ["amazon"]
}

resource "aws_instance" "nginx_vpc_main" {
  ami                    = data.aws_ami.al2_x86_vpc_main.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc_main.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.sg_ec2_vpc_main.id, ]

  user_data                   = local.user_data
  user_data_replace_on_change = true

  tags = {
    Name = "Instance-VPC-Main"
    ELB  = "elb-1"
  }

  timeouts {
    create = "10m"
  }
}

resource "aws_instance" "nginx_vpc_secondary" {
  provider = aws.region_secondary

  ami                    = data.aws_ami.al2_x86_vpc_secondary.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc_secondary.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.sg_ec2_vpc_secondary.id, ]

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    encrypted = false
  }

  tags = {
    Name = "Instance-VPC-Secondary"
    ELB  = "elb-1"
  }

  timeouts {
    create = "10m"
  }
}