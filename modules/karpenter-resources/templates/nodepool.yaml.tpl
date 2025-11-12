apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${nodepool_name}
spec:
  # Template for nodes provisioned by this NodePool
  template:
    metadata:
      labels:
        nodepool: ${nodepool_name}
        workload-type: ${workload_type}
%{ for key, value in node_labels ~}
        ${key}: "${value}"
%{ endfor ~}

    spec:
      # Reference to EC2NodeClass
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${nodeclass_name}

      # Requirements for node selection
      requirements:
        # Capacity type: spot, on-demand, or both
        - key: karpenter.sh/capacity-type
          operator: In
          values: ${jsonencode(capacity_types)}

        # Architecture
        - key: kubernetes.io/arch
          operator: In
          values: ${jsonencode(architectures)}

        # Instance categories
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ${jsonencode(instance_categories)}

        # Instance generations
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["${instance_generation}"]

%{ if length(instance_types) > 0 ~}
        # Specific instance types (optional)
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ${jsonencode(instance_types)}
%{ endif ~}

%{ if length(availability_zones) > 0 ~}
        # Availability zones
        - key: topology.kubernetes.io/zone
          operator: In
          values: ${jsonencode(availability_zones)}
%{ endif ~}

      # Taints (optional)
%{ if length(taints) > 0 ~}
      taints:
%{ for taint in taints ~}
        - key: ${taint.key}
          value: ${taint.value}
          effect: ${taint.effect}
%{ endfor ~}
%{ endif ~}

      # Startup taints (removed after node is ready)
      startupTaints:
        - key: node.kubernetes.io/not-ready
          effect: NoSchedule

  # Resource limits for this NodePool
  limits:
    cpu: "${cpu_limit}"
    memory: "${memory_limit}Gi"

  # Disruption settings
  disruption:
    # Consolidation policy
    consolidationPolicy: ${consolidation_policy}
    consolidateAfter: 1m
    # Budget for voluntary disruptions
    budgets:
      - nodes: "${disruption_budget_nodes}"
        schedule: "${disruption_budget_schedule}"
        duration: 8h
        nodes: "0"

    # Expiration settings
%{ if expire_after_enabled ~}
    expireAfter: ${expire_after_duration}
%{ endif ~}

  # Weight for scheduling priority
  weight: ${weight}
