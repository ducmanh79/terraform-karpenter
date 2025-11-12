terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# EC2NodeClass - Defines the infrastructure configuration for nodes
resource "kubectl_manifest" "ec2nodeclass" {
  yaml_body = templatefile("${path.module}/templates/ec2nodeclass.yaml.tpl", {
    nodeclass_name            = var.nodeclass_name
    ami_family                = var.ami_family
    ami_id                    = var.ami_id
    node_iam_role_name        = var.node_iam_role_name
    cluster_name              = var.cluster_name
    cluster_security_group_id = var.cluster_security_group_id
    environment               = var.environment
    disk_size                 = var.disk_size
    additional_tags           = var.additional_tags
  })

  depends_on = [var.karpenter_helm_release_id]
}

# NodePools - Defines the provisioning behavior and constraints
# Create multiple NodePools based on the nodepools variable
resource "kubectl_manifest" "nodepool" {
  for_each = { for np in var.nodepools : np.name => np }

  yaml_body = templatefile("${path.module}/templates/nodepool.yaml.tpl", {
    nodepool_name              = each.value.name
    nodeclass_name             = var.nodeclass_name
    workload_type              = each.value.workload_type
    node_labels                = each.value.node_labels
    capacity_types             = each.value.capacity_types
    architectures              = each.value.architectures
    instance_categories        = each.value.instance_categories
    instance_generation        = each.value.instance_generation
    instance_types             = each.value.instance_types
    availability_zones         = var.availability_zones
    taints                     = each.value.taints
    cpu_limit                  = each.value.cpu_limit
    memory_limit               = each.value.memory_limit
    consolidation_policy       = each.value.consolidation_policy
    disruption_budget_nodes    = each.value.disruption_budget_nodes
    disruption_budget_schedule = each.value.disruption_budget_schedule
    expire_after_enabled       = each.value.expire_after_enabled
    expire_after_duration      = each.value.expire_after_duration
    weight                     = each.value.weight
  })

  depends_on = [kubectl_manifest.ec2nodeclass]
}
