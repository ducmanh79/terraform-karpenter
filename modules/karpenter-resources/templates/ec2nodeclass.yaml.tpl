apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${nodeclass_name}
spec:
  # AMI Family (Bottlerocket, AL2023, etc.)
  amiFamily: ${ami_family}
%{ if ami_id != "" && ami_id != "auto" ~}
  # Custom AMI ID
  amiSelectorTerms:
    - id: ${ami_id}
%{ endif ~}
  # IAM Role for nodes
  role: "${node_iam_role_name}"

  # Subnet Selection - Uses tags to discover subnets
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${cluster_name}"

  # Security Group Selection
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${cluster_name}"
    - id: "${cluster_security_group_id}"

  amiSelectorTerms:
    - alias: bottlerocket@latest

  # Bottlerocket-specific user data
  userData: |
    [settings.kubernetes]
    cluster-name = "${cluster_name}"

    [settings.kubernetes.node-labels]
    "os-type" = "bottlerocket"

    [settings.host-containers.admin]
    enabled = false

  # Tags applied to EC2 instances
  tags:
    Name: "${cluster_name}-karpenter-node"
    karpenter.sh/discovery: "${cluster_name}"
    Environment: "${environment}"
    ManagedBy: "karpenter"
%{ for key, value in additional_tags ~}
    ${key}: "${value}"
%{ endfor ~}

  # Block Device Mappings
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: ${disk_size}Gi
        volumeType: gp3
        encrypted: true
        deleteOnTermination: true

  # Metadata Options
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 2
    httpTokens: required
