output "nodeclass_name" {
  description = "Name of the created EC2NodeClass"
  value       = var.nodeclass_name
}

output "nodepool_names" {
  description = "Names of the created NodePools"
  value       = [for np in var.nodepools : np.name]
}

output "ec2nodeclass_manifest" {
  description = "The EC2NodeClass manifest"
  value       = kubectl_manifest.ec2nodeclass.yaml_body
  sensitive   = false
}

output "nodepool_manifests" {
  description = "The NodePool manifests"
  value       = { for k, v in kubectl_manifest.nodepool : k => v.yaml_body }
  sensitive   = false
}
