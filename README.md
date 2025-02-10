# EKS on Terraform

A simple AWS EKS (Kuberentes) Cluster that runs a service with 2 pods (containers) behind an Application Load Balancer. All on Terraform.

## Pre-requisites

Before depoyment, make sure you have the following packages installed:

```sh
brew install terraform awscli kubernetes-cli helm
```

Ensure you have configured your AWS Credentials on your local computer using `aws configure` command and have enough access to deploy into AWS.

## Deployment Instructions

Before you deploy the changes, make sure you update `default` values in `vars-configs.tf` according to what you already have deployed in AWS:

```
variable "principal_arn"
variable "cluster_vpc_id"
variable "subnet_ids"
```

Next, on root folder, execute:

```sh
terraform init
terraform apply
```

Please wait as all the infrastructure is deployed. Please refer to the `eks_post_init.tf` for a set of instructions that will provision the service, deployment and ingress (ALB) in the EKS Cluster.

It's recommended that you head over the EKS AWS Console, to see all of the resources, and configs that were deployed.

## Accessing the Sample App

Head over to the AWS Console > EC2 > Application Load Balancer. Select the k8s ALB, and copy the DNS URL and open it in your browser. If everything went well, you should see the application running on an URL like this:

```
k8s-ekssampl-ekssampl-b4ae9951ee-12345667.us-east-1.elb.amazonaws.com
```

## EKS Provisioning Commands (`eks_post_init.tf`):

Terraform will automatically run these commands for your, but in case, below are a set of `aws`, `kubectl`, `helm` commands that will interact with the cluster and apply the required configs to run a sample application behind an ALB:

```sh
# Update the kubeconfig (locally)
aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}

# Deploy the sample application
kubectl apply -f ${path.module}/configs/eks-deployment.yaml
kubectl apply -f ${path.module}/configs/eks-service.yaml

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
  kubectl apply -f ${path.module}/configs/eks-ingress.yaml && break || sleep 30
done
```

## Destroy Instruction

EKS will provision automatically an ALB (using AWS Load Balancer Controller), and this resource is not managed through Terraform.

Please execute the following commands to remove any left over infrastructure that was automatically created by EKS:

```sh
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete -f ./configs/eks-deployment.yaml
kubectl delete -f ./configs/eks-service.yaml
kubectl delete -f ./configs/eks-ingress.yaml
kubectl delete serviceaccount aws-load-balancer-controller -n kube-system
```

Then finalize with,

```
terraform destroy
```
