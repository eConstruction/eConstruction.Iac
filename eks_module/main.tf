variable "vpc_id" {}
variable "subnet_ids" {}
variable "control_plane_subnet_ids" {}

resource "aws_eks_cluster" "main" {
  name     = "econstruction-cluster"
  version  = "1.24"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks,
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "stw-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.control_plane_subnet_ids

  scaling_config {
    desired_size = 1
    max_size     = 6
    min_size     = 2
  }

  ami_type = "AL2_x86_64"
  instance_types = ["t3.medium"]
}

resource "aws_iam_role" "eks" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = aws_iam_policy.eks.arn
}

resource "aws_iam_policy" "eks" {
  name        = "eks-policy"
  path        = "/"
  description = "EKS Policy"
  policy      = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "node" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node.arn
}

resource "aws_iam_policy" "node" {
  name        = "eks-node-policy"
  path        = "/"
  description = "EKS Node Policy"
  policy      = file("${path.module}/iam_policy.json")
}
