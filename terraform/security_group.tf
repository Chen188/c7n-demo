locals {
  public_egress = [
    {
      description      = "for all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  elb_ingress_rules = [{
    name        = "HTTPS"
    port        = 443
    description = "Ingress rules for port 443"
    },
    {
      name        = "HTTP"
      port        = 80
      description = "Ingress rules for port 80"
  }]

  ec2_ingress_rules = [{
    name        = "HTTP"
    port        = 80
    description = "Allow TCP 80 from ELB"
  }]
}

resource "aws_security_group" "sg_elb" {
  name        = "SG-ELB"
  description = "Allow HTTP inbound traffic for ELB"
  vpc_id      = module.vpc_main.vpc_id
  egress      = local.public_egress

  dynamic "ingress" {
    for_each = local.elb_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "SG-ELB-1"
  }
}

resource "aws_security_group" "sg_ec2_vpc_main" {
  name        = "SG-EC2-VPC-Main"
  description = "Allow HTTP inbound traffic for EC2"
  vpc_id      = module.vpc_main.vpc_id
  egress      = local.public_egress

  dynamic "ingress" {
    for_each = local.ec2_ingress_rules

    content {
      description     = ingress.value.description
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      protocol        = "tcp"
      security_groups = [aws_security_group.sg_elb.id]
    }
  }

  tags = {
    Name = "SG-EC2-VPC-Main"
  }
}


resource "aws_security_group" "sg_ec2_vpc_secondary" {
  provider = aws.region_secondary

  name        = "SG-EC2-VPC-Secondary"
  description = "Allow HTTP inbound traffic for EC2"
  vpc_id      = module.vpc_secondary.vpc_id
  egress      = local.public_egress

  dynamic "ingress" {
    for_each = local.ec2_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      # todo, restrict to elb's subnet cidr
      cidr_blocks = [module.vpc_main.vpc_cidr_block]
    }
  }

  tags = {
    Name = "SG-EC2-VPC-Secondary"
  }
}


resource "aws_security_group" "sg_ec2_eks_ng" {
  name        = "SG-EKS-NG"
  description = "Allow HTTP inbound traffic for EKS NG"
  vpc_id      = module.vpc_main.vpc_id
  egress      = local.public_egress

  dynamic "ingress" {
    for_each = local.ec2_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      self        = true
    }
  }

  tags = {
    Name = "SG-EKS-NG"
  }
}