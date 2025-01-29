# VPC Module

module "vpc" {
  source   = "./vpc_module"
  region   = "us-east-1"
  vpc_cidr = "10.0.0.0/16"
  public_subnets = {
    "us-east-1a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    },
    "us-east-1b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  }
  private_subnets = {
    "us-east-1a" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1a"
    },
    "us-east-1b" = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-1b"
    }
  }
}

# EKS Module

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = "econstruction-cluster"
  cluster_version                = "1.24"
  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.private_subnet_ids

  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = ["t3.medium"]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    stw_node_wg = {
      iam_role_name = "stw-node-group-role"
      min_size      = 1
      max_size      = 6
      desired_size  = 1
    }
  }

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }
}

output "eks_cluster_endpoint" {
  value     = data.aws_eks_cluster.cluster.endpoint
  sensitive = true
}

output "eks_auth_token" {
  value     = data.aws_eks_cluster_auth.cluster.token
  sensitive = true
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

resource "aws_iam_policy" "eks_cluster_additional_policy" {
  name        = "${module.eks.cluster_name}-alb-eks-policy"
  path        = "/"
  description = "Additional IAM policy for EKS cluster"
  policy      = file("iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = module.eks.cluster_iam_role_name # Ensure this references the IAM role created for the EKS cluster
  policy_arn = aws_iam_policy.eks_cluster_additional_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_group_policy_attachment" {
  role       = module.eks.eks_managed_node_groups["stw_node_wg"].iam_role_name
  policy_arn = aws_iam_policy.eks_cluster_additional_policy.arn
}


# VPC CNI Module

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}


# ALB Controller

resource "null_resource" "helm_repo_add" {
  provisioner "local-exec" {
    command = "helm repo add eks https://aws.github.io/eks-charts && helm repo update"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  provider = helm

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.11.0"
  timeout    = 600 # Increase timeout to 600 seconds (10 minutes)

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  depends_on = [
    module.eks,                   # Ensures the EKS cluster is created
    data.aws_eks_cluster.cluster, # Ensures cluster data is retrieved
    data.aws_eks_cluster_auth.cluster
  ]
}


resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicyNew"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller in EKS"

  policy = file("iam_policy.json")
}

resource "aws_iam_role" "aws_load_balancer_controller_role" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
