terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # This version is required for the latest EKS module features
      version = "~> 5.0" 
    }
  }
}