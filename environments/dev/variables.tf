variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_account_id" {
  description = "AWS Account ID for this environment"
  type        = string
  default     = ""
}

variable "assume_role_name" {
  description = "IAM role name to assume for multi-account deployment"
  type        = string
  default     = "TerraformDeployRole"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC flow logs"
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# EKS Cluster Variables
variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# EKS Node Group Variables
variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_group_name" {
  description = "Name of the node group"
  type = string
  default = "core"
}

# Karpenter Variables
variable "karpenter_version" {
  description = "Version of Karpenter to install"
  type        = string
  default     = "1.0.1"
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_replicas" {
  description = "Number of Karpenter controller replicas"
  type        = number
  default     = 2
}

# Karpenter Resources Variables
variable "karpenter_nodeclass_name" {
  description = "Name of the EC2NodeClass"
  type        = string
  default     = "default"
}

variable "karpenter_ami_family" {
  description = "AMI family for Karpenter nodes"
  type        = string
  default     = "AL2023"
}

variable "karpenter_ami_id" {
  description = "AMI ID for Karpenter nodes (use 'auto' to let Karpenter auto-select based on amiFamily)"
  type        = string
  default     = "auto"
}

variable "karpenter_node_disk_size" {
  description = "Disk size for Karpenter nodes in GB"
  type        = number
  default     = 20
}

# Karpenter NodePools Configuration
variable "karpenter_nodepools" {
  description = "List of Karpenter NodePool configurations"
  type = list(object({
    name                       = string
    workload_type              = string
    node_labels                = map(string)
    capacity_types             = list(string)
    architectures              = list(string)
    instance_categories        = list(string)
    instance_generation        = string
    instance_types             = list(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    cpu_limit                  = string
    memory_limit               = string
    consolidation_policy       = string
    disruption_budget_nodes    = string
    disruption_budget_schedule = string
    expire_after_enabled       = bool
    expire_after_duration      = string
    weight                     = number
  }))
  default = []
}