terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  required_version = ">= 1.2"
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  # Uncomment and configure for multi-account setup
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.assume_role_name}"
  # }

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
      Workspace   = terraform.workspace
    }
  }
}

# Data source for Kubernetes authentication
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Configure Kubectl Provider
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  name               = "${var.project_name}-${var.environment}"
  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway       = var.enable_nat_gateway
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days

  tags = var.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types            = var.cluster_enabled_log_types

  node_group_desired_size   = var.node_group_desired_size
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_instance_types = var.node_group_instance_types
  node_group_capacity_type  = var.node_group_capacity_type
  node_group_disk_size      = var.node_group_disk_size
  node_group_name           = var.node_group_name

  tags = var.common_tags

  depends_on = [module.networking]
}

# Karpenter Module
module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name      = module.eks.cluster_id
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  node_iam_role_arn = module.eks.node_iam_role_arn
  aws_region        = var.aws_region

  karpenter_version   = var.karpenter_version
  karpenter_namespace = var.karpenter_namespace
  karpenter_replicas  = var.karpenter_replicas

  tags = var.common_tags

  depends_on = [module.eks]
}

# Karpenter Resources Module (NodePool and EC2NodeClass)
module "karpenter_resources" {
  source = "../../modules/karpenter-resources"

  cluster_name              = module.eks.cluster_id
  node_iam_role_name        = module.eks.node_iam_role_name
  cluster_security_group_id = module.eks.cluster_primary_security_group_id
  karpenter_helm_release_id = module.karpenter.helm_release_id
  environment               = var.environment

  # EC2NodeClass settings
  nodeclass_name  = var.karpenter_nodeclass_name
  ami_family      = var.karpenter_ami_family
  ami_id          = var.karpenter_ami_id
  disk_size       = var.karpenter_node_disk_size
  additional_tags = var.common_tags

  # NodePools configuration (list of NodePools)
  nodepools          = var.karpenter_nodepools
  availability_zones = var.availability_zones

  depends_on = [module.karpenter]
}

# Data source to get current AWS account information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
