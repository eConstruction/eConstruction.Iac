# variable "vpc_id" {
#   type = string
# }

# variable "subnets" {
#   type = list(string)
# }

# variable "security_groups" {
#   type = list(string)
# }



variable "vpc_id" {
  description = "VPC ID where the ALB and instances are created"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group attached to the ALB and instances"
  type        = string
}