variable "vpc_id" {
  description = "VPC ID where the cluster and nodes reside."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for the EKS control plane."
  type        = list(string)
}
