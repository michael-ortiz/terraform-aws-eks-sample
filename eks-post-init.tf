## Commands to run after the cluster is created
## This will create a namespace, deploy the sample application, 
## and create the ingress which will expose the application to the internet over an ALB

resource "null_resource" "eks_post_init" {
  count = var.automatic_provisioning ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      # Update the kubeconfig
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}

      # Deploy the sample application
      kubectl apply -f ${path.module}/manifests/eks-deployment.yaml
      kubectl apply -f ${path.module}/manifests/eks-service.yaml
      
      # Create Service Account for AWS Load Balancer Controller
      kubectl create serviceaccount aws-load-balancer-controller -n kube-system
      kubectl annotate serviceaccount aws-load-balancer-controller -n kube-system eks.amazonaws.com/role-arn=${aws_iam_role.aws_load_balancer_controller_role.arn}

      # Deploy the AWS Load Balancer Controller
      helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${var.cluster_name} \
        --set serviceAccount.create=false \
        --set vpcId=${var.cluster_vpc_id} \
        --set serviceAccount.name=aws-load-balancer-controller

      # Deploy the Ingress
      sleep 30
      for i in {1..10}; do
        kubectl apply -f ${path.module}/manifests/eks-ingress.yaml && break || sleep 30
      done
    EOT
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.default,
    aws_eks_access_entry.default,
    aws_eks_access_policy_association.default_admin,
  ]
}

