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
      min_size       = 1
      max_size       = 3
      desired_size   = 2
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

  # --- ACCESS CONTROL ADDITIONS ---
  # These lines tell EKS to trust your Bastion role
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::637423276119:role/bastion-ssm-role"
      username = "bastion-ssm-role"
      groups   = ["system:masters"] # Gives Bastion full admin rights
    }
  ]
}
# Add this to the bottom of main.tf
resource "aws_security_group_rule" "bastion_to_eks_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  
  # This uses the ID of the Bastion SG you created in bastion.tf
  source_security_group_id = aws_security_group.bastion_sg.id
  
  # This targets the Security Group created by your EKS module
  security_group_id        = module.eks.cluster_primary_security_group_id
  
  description              = "Allow Bastion to communicate with EKS API"
}

# This fetches the authentication token for your EKS cluster
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = "https://localhost:8443"
  # cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  insecure               = true # Required because of the localhost tunnel
}