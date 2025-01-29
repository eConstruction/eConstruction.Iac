variable "region" {
  description = "AWS region for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "Public subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Private subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}
