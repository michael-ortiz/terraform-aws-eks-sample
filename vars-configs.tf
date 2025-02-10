variable "aws_region" {
  description = "The AWS region to deploy the EKS Cluster into"
  type        = string
  default     = "us-east-1"
}

variable "principal_arn" {
  description = "The ARN of the principal to grant access to the EKS Cluster. Use the ARN the the Role or User you used to deploy the EKS Cluster."
  type        = string
  default     = "arn:aws:iam::1234567890:user/YOUR_USER" // Replace with your ARN
}

variable "cluster_vpc_id" {
  description = "The ID of the VPC to launch the EKS cluster into. For this demo, we will use the default VPC."
  type        = string
  default     = "vpc-1234567890" // REPLACE WITH YOUR VPC ID
}

variable "subnet_ids" {
  description = "The IDs of the subnets to launch the EKS cluster into. For this demo, we will use the default VPC subnets."
  type        = list(string)
  default = [
    "subnet-aaaaaaaaaaaaaaaaa", // us-east-1a - Public -- REPLACE WITH YOUR SUBNET ID
    "subnet-bbbbbbbbbbbbbbbbb", // us-east-1b - Public -- REPLACE WITH YOUR SUBNET ID
  ]
}

variable "node_instance_type" {
  description = "The instance type to use for the EKS Node Group"
  type        = string
  default     = "t3.medium"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster" // If you change this, make sure to also update the configs .yaml references
}

variable "default_namespace" {
  description = "The default namespace to deploy the sample application into"
  type        = string
  default     = "eks-sample-app"
}

variable "default_eks_access_policy_arn" {
  # https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
  description = "The ARN of the policy which will be assigned to the root account for access to the EKS Cluster"
  type        = string
  # This is the default policy that grants full access to the EKS Cluster, you may want to restrict this to a specific IAM Role or User
  # https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

# Enable automatic provisioning of the EKS Cluster.
variable "automatic_provisioning" {
  description = "Enable automatic provisioning of the EKS Cluster which executes the init scripts on the EKS Cluster"
  type        = bool
  default     = true
}