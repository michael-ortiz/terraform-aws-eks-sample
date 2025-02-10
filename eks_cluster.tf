resource "aws_eks_cluster" "main" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.32"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = var.subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy,
    aws_iam_policy.aws_load_balancer_controller_policy,
    aws_ec2_tag.vpc_elb_subnets,
    aws_ec2_tag.vpc_cluster_subnets,
  ]
}

### Access Control to EKS API ###
resource "aws_eks_access_entry" "default" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.principal_arn
  type          = "STANDARD"
}

# Grant the root account access to the EKS Cluster via an AWS Managed Policy
resource "aws_eks_access_policy_association" "default_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = var.default_eks_access_policy_arn
  principal_arn = var.principal_arn

  access_scope {
    type = "cluster"
  }
}

### Required Add-ons ###
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

## Add required tags to the VPC subnets for the EKS Cluster
resource "aws_ec2_tag" "vpc_elb_subnets" {
  count       = length(var.subnet_ids)
  resource_id = element(var.subnet_ids, count.index)
  key         = "kubernetes.io/role/elb"
  value       = 1
}

resource "aws_ec2_tag" "vpc_cluster_subnets" {
  count       = length(var.subnet_ids)
  resource_id = element(var.subnet_ids, count.index)
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "owned"
}
