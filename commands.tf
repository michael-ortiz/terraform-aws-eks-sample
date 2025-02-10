## Commands to run after the cluster is created
## This will create a namespace, deploy the sample application, 
## and create the ingress which will expose the application to the internet over an ALB

resource "null_resource" "kube_config" {
  count = var.automatic_provisioning ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}
    EOT
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.default
  ]
}

resource "null_resource" "eks_on_init" {
  count = var.automatic_provisioning ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      kubectl create namespace ${var.default_namespace}
      kubectl config set-context --current --namespace=${var.default_namespace}

      kubectl apply -f ${path.module}/configs/eks-deployment.yaml
      kubectl apply -f ${path.module}/configs/eks-service.yaml

      helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=my-eks-cluster \
        --set serviceAccount.create=false \
        --set vpcId={REPLACE_WITH_YOUR_VPC_ID} \
        --set serviceAccount.name=aws-load-balancer-controller
    EOT
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.default,
    null_resource.kube_config,
    aws_eks_access_entry.default,
    aws_eks_access_policy_association.default_admin,
  ]
}

resource "null_resource" "ingress" {
  count = var.automatic_provisioning ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..10}; do
        kubectl apply -f ${path.module}/configs/eks-ingress.yaml && break || sleep 30
      done
    EOT
  }

  depends_on = [
    null_resource.eks_on_init,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}
