output "cluster_id" {
  value     = aws_eks_cluster.main.id
  sensitive = false
}

output "cluster_endpoint" {
  value     = aws_eks_cluster.main.endpoint
  sensitive = true
}

output "cluster_security_group_id" {
  value     = aws_eks_cluster.main.vpc_config[0].security_group_ids
  sensitive = false
}
