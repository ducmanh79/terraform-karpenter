# Karpenter Resources Module

This module creates Kubernetes resources (NodePool and EC2NodeClass) for Karpenter using the `kubectl` provider and template files.

## Overview

This module demonstrates how to use Terraform templates (`.tpl` files) with the `kubectl` provider to manage Kubernetes YAML manifests dynamically.

## Module Structure

```
modules/karpenter-resources/
├── main.tf                           # kubectl_manifest resources
├── variables.tf                      # Input variables
├── outputs.tf                        # Module outputs
├── README.md                         # This file
└── templates/
    ├── ec2nodeclass.yaml.tpl         # EC2NodeClass template
    └── nodepool.yaml.tpl             # NodePool template
```

## How Templates Work

### 1. Template Files (`.tpl`)

Template files contain YAML with Terraform variable placeholders:

```yaml
# Example from ec2nodeclass.yaml.tpl
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${nodeclass_name}
spec:
  amiFamily: ${ami_family}
  role: "${node_iam_role_name}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${cluster_name}"
```

### 2. Terraform Processing

Terraform's `templatefile()` function renders the template:

```hcl
resource "kubectl_manifest" "ec2nodeclass" {
  yaml_body = templatefile("${path.module}/templates/ec2nodeclass.yaml.tpl", {
    nodeclass_name     = var.nodeclass_name
    ami_family         = var.ami_family
    node_iam_role_name = var.node_iam_role_name
    cluster_name       = var.cluster_name
    # ... more variables
  })
}
```

### 3. Result

Terraform generates valid Kubernetes YAML and applies it to the cluster:

```yaml
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  role: "my-eks-dev-cluster-node-role"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "my-eks-dev-cluster"
```

## Resources Created

### 1. EC2NodeClass

Defines the infrastructure configuration for nodes:
- **AMI Family**: AL2023 (Amazon Linux 2023)
- **IAM Role**: Uses EKS node role
- **Subnets**: Discovered via `karpenter.sh/discovery` tag
- **Security Groups**: Uses cluster security group
- **Block Devices**: 20GB gp3 encrypted EBS volume
- **Metadata Options**: IMDSv2 required

### 2. NodePool

Defines provisioning behavior and constraints:
- **Capacity Types**: Spot and On-Demand
- **Instance Categories**: c, m, r, t (compute, memory, general, burstable)
- **Instance Generation**: 5+ (t3, m5, c5, etc.)
- **Architecture**: amd64
- **Resource Limits**: 1000 CPU / 1000GB RAM
- **Consolidation**: Enabled when underutilized
- **Disruption Budget**: Max 10% nodes at once

## Usage

```hcl
module "karpenter_resources" {
  source = "../../modules/karpenter-resources"

  cluster_name              = "my-cluster"
  node_iam_role_name        = "my-cluster-node-role"
  cluster_security_group_id = "sg-12345678"
  karpenter_helm_release_id = module.karpenter.helm_release_id
  environment               = "dev"

  # EC2NodeClass settings
  nodeclass_name = "default"
  ami_family     = "AL2023"
  disk_size      = 20

  # NodePool settings
  nodepool_name       = "default"
  workload_type       = "general"
  capacity_types      = ["spot", "on-demand"]
  instance_categories = ["c", "m", "r", "t"]
  cpu_limit           = "1000"
  memory_limit        = "1000"
}
```

## Template Features

### Dynamic Values

Templates can reference Terraform outputs and data sources:

```hcl
# In main.tf
cluster_name = module.eks.cluster_id
node_iam_role_name = module.eks.node_iam_role_name

# In template
role: "${node_iam_role_name}"  # Becomes: "my-cluster-node-role"
```

### Conditional Blocks

Use `%{ if }` directives for conditional content:

```yaml
%{ if length(instance_types) > 0 ~}
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ${jsonencode(instance_types)}
%{ endif ~}
```

### Loops

Use `%{ for }` directives to iterate:

```yaml
%{ for key, value in additional_tags ~}
    ${key}: "${value}"
%{ endfor ~}
```

### JSON Encoding

Use `jsonencode()` for Terraform lists/objects:

```yaml
values: ${jsonencode(capacity_types)}
# Result: ["spot","on-demand"]
```

## Dependencies

The module depends on:
1. **Karpenter Helm Release**: Must be installed first
2. **EKS Cluster**: For node role and security groups
3. **kubectl Provider**: Configured with cluster auth

## Verification

After `terraform apply`, verify the resources:

```bash
# Check EC2NodeClass
kubectl get ec2nodeclass

# Check NodePool
kubectl get nodepool

# View NodePool details
kubectl describe nodepool default

# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

## Testing Karpenter

Deploy a test workload to trigger node provisioning:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 5
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      containers:
      - name: inflate
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        resources:
          requests:
            cpu: 1
EOF
```

Watch Karpenter provision nodes:

```bash
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
kubectl get nodes --watch
```

## Configuration Examples

### Spot-Only NodePool

```hcl
capacity_types = ["spot"]
disruption_budget_nodes = "100%"  # Allow aggressive consolidation
```

### Memory-Optimized Workloads

```hcl
instance_categories = ["r"]  # r5, r6i, etc.
node_labels = {
  "workload-type" = "memory-intensive"
}
```

### GPU Instances

```hcl
instance_types = ["g4dn.xlarge", "g5.xlarge"]
taints = [
  {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NoSchedule"
  }
]
```

## Advantages of This Approach

1. ✅ **Single Source of Truth**: Infrastructure and K8s resources in one place
2. ✅ **Dynamic Configuration**: Use Terraform outputs directly
3. ✅ **Version Control**: Templates tracked alongside infrastructure
4. ✅ **Dependency Management**: Terraform ensures correct ordering
5. ✅ **Type Safety**: Terraform validates variable types
6. ✅ **Reusability**: One template, multiple environments

## Troubleshooting

### Template Rendering Issues

View rendered template:

```bash
terraform console
> templatefile("./templates/nodepool.yaml.tpl", {...})
```

### kubectl Provider Errors

Check provider configuration:

```hcl
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```

### Karpenter Not Provisioning

Check NodePool status:

```bash
kubectl describe nodepool default
```

Check Karpenter controller logs:

```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=100
```

## References

- [Karpenter Documentation](https://karpenter.sh/)
- [Terraform templatefile() Function](https://www.terraform.io/language/functions/templatefile)
- [kubectl Provider](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs)
