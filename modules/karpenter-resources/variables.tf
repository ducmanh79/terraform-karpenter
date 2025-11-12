# Required Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_iam_role_name" {
  description = "Name of the IAM role for nodes"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "karpenter_helm_release_id" {
  description = "ID of the Karpenter Helm release (for dependency)"
  type        = string
}

# EC2NodeClass Variables
variable "nodeclass_name" {
  description = "Name of the EC2NodeClass"
  type        = string
  default     = "default"
}

variable "ami_family" {
  description = "AMI family for nodes (AL2, AL2023, Bottlerocket, Ubuntu)"
  type        = string
  default     = "AL2023"
}

variable "ami_id" {
  description = "AMI ID for nodes (use 'auto' to let Karpenter auto-select based on amiFamily)"
  type        = string
  default     = "auto"
}

variable "disk_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to apply to EC2 instances"
  type        = map(string)
  default     = {}
}

# Shared Variables
variable "availability_zones" {
  description = "List of availability zones (empty = all zones in region)"
  type        = list(string)
  default     = []
}

# NodePools Configuration
variable "nodepools" {
  description = "List of NodePool configurations"
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
  default = [
    {
      name                       = "default"
      workload_type              = "general"
      node_labels                = {}
      capacity_types             = ["on-demand"]
      architectures              = ["amd64"]
      instance_categories        = ["c", "m", "r", "t"]
      instance_generation        = "5"
      instance_types             = []
      taints                     = []
      cpu_limit                  = "1000"
      memory_limit               = "1000"
      consolidation_policy       = "WhenEmptyOrUnderutilized"
      disruption_budget_nodes    = "10%"
      disruption_budget_schedule = "0 9 * * mon-fri"
      expire_after_enabled       = false
      expire_after_duration      = "720h"
      weight                     = 10
    }
  ]
}
