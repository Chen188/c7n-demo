# VPC for LB and EKS
module "vpc_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  providers = {
    aws = aws.region_main
  }

  name = "vpc-main"

  cidr = "10.1.0.0/16"
  azs  = slice(data.aws_availability_zones.available_main.names, 0, 3)

  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = {

  }
}

# VPC for the EC2 that attached to main VPC's LB
module "vpc_secondary" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  providers = {
    aws = aws.region_secondary
  }

  name = "vpc-secondary"

  cidr = "10.2.0.0/16"
  azs  = slice(data.aws_availability_zones.available_secondary.names, 0, 3)

  # for ec2 behind ELB
  private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets  = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


#Initiate Peering connection request from main
resource "aws_vpc_peering_connection" "main_secondary" {
  provider = aws.region_main
  vpc_id   = module.vpc_main.vpc_id
  # auto_accept = true
  peer_vpc_id = module.vpc_secondary.vpc_id
  peer_region = var.region_secondary
  timeouts {
    create = "2m"
  }
}

#Accept VPC peering request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region_secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.main_secondary.id
  auto_accept               = true
}

# Create routes from requestor to acceptor
resource "aws_route" "requestor" {
  count                     = length(module.vpc_secondary.private_subnets_cidr_blocks)
  route_table_id            = module.vpc_main.public_route_table_ids[0]
  destination_cidr_block    = module.vpc_secondary.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.main_secondary.id
}

# Create routes from acceptor to requestor
resource "aws_route" "acceptor" {
  provider                  = aws.region_secondary
  count                     = length(module.vpc_main.public_subnets_cidr_blocks)
  route_table_id            = module.vpc_secondary.private_route_table_ids[0]
  destination_cidr_block    = module.vpc_main.public_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.main_secondary.id
}