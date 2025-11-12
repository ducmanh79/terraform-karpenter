output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_controller_role_name" {
  description = "Name of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.name
}

output "karpenter_queue_name" {
  description = "Name of the SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter.name
}

output "karpenter_queue_arn" {
  description = "ARN of the SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter.arn
}

output "karpenter_namespace" {
  description = "Kubernetes namespace where Karpenter is installed"
  value       = var.karpenter_namespace
}

output "karpenter_version" {
  description = "Version of Karpenter installed"
  value       = var.karpenter_version
}

output "helm_release_id" {
  description = "ID of the Karpenter Helm release"
  value       = helm_release.karpenter.id
}
