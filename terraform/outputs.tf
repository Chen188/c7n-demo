output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

# output "cluster_security_group_id" {
#   description = "Security group ids attached to the cluster control plane"
#   value       = module.eks.cluster_security_group_id
# }

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "region_main" {
  description = "Main AWS region"
  value       = var.region_main
}

output "region_secondary" {
  description = "Secondary AWS region"
  value       = var.region_secondary
}

output "custodian_lambda_exec_role" {
  value       = aws_iam_role.custodian_lambda_exec_role.arn
  description = "IAM role assumed by lambda created by cloud custodian"
}

output "custodian_cicd_role" {
  value       = aws_iam_role.custodian_cicd_role.arn
  description = "IAM role assumed by CICD env"
}

output "alb_cross_region" {
  value       = aws_lb.alb.dns_name
  description = "dns name of alb-cross-region"
}