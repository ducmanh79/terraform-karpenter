variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  type        = string
}

variable "node_iam_role_arn" {
  description = "IAM role ARN of the EKS nodes (for Karpenter to use)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
