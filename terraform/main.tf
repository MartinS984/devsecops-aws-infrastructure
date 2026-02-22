# 1. Create a KMS Key for Secret Encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Compliance requirement
}

# 2. Define the EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "banking-cluster-prod"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets 

  # Zero Trust: Secrets Encryption
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }

  eks_managed_node_groups = {
    secure_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.private_subnets
    }
  }

  enable_irsa = true

  # Unified Security Endpoint Settings
  cluster_endpoint_public_access  = false # Best practice for banks
  cluster_endpoint_private_access = true
  
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}