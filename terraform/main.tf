# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes
# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

locals {
  default_tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

provider "aws" {
  region = var.region_main
  alias  = "region_main"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region = var.region_secondary
  alias  = "region_secondary"

  default_tags {
    tags = local.default_tags
  }
}

data "aws_availability_zones" "available_main" {
  provider = aws.region_main
}

data "aws_availability_zones" "available_secondary" {
  provider = aws.region_secondary
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
