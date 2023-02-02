
locals {
  cluster_name = "project-eks-${random_string.suffix.result}"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = local.cluster_name
  cluster_version = "1.24"

  vpc_id                         = module.vpc_main.vpc_id
  subnet_ids                     = module.vpc_main.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    vpc_security_group_ids = [aws_security_group.sg_ec2_eks_ng.id, ]
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}
