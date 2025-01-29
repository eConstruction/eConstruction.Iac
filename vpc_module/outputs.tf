output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = {
    for subnet in aws_subnet.public : subnet.availability_zone => subnet.id
  }
}

# output "public_subnet_ids" {
#   value = {
#     for subnet in aws_subnet.public : subnet.availability_zone => subnet.id
#   }
# }

# output "public_subnet_ids" {
#   value = {
#     "us-east-1a" = aws_subnet.public["us-east-1a"].id
#     "us-east-1b" = aws_subnet.public["us-east-1b"].id
#   }
# }

# output "public_subnet_ids" {
#   value = {
#     for az, subnet in aws_subnet.public : az => subnet.id
#   }
# }

# output "public_subnets" {
#   value = {
#     for idx, s in aws_subnet.public : "${s.availability_zone}-${idx}" => s.id
#   }
# }

# output "public_subnets" {
#   value = {
#     for s in aws_subnet.public : s.availability_zone => s.id
#   }
# }

# output "public_subnet_ids" {
#   value = [for subnet in aws_subnet.public : subnet.id]
# }

# output "public_subnet_ids" {
#   value = {
#     "us-east-1a" = aws_subnet.public["1a"].id
#     "us-east-1b" = aws_subnet.public["1b"].id
#   }
# }

output "public_subnets" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "security_group_id" {
  value = aws_security_group.default.id
}


