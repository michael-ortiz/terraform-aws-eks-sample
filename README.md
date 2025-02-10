# EKS Terraform 

## Pre-requisites

All of the following will need to be installed:

```sh
brew install awscli
brew install terraform
brew install kubernetes-cli
```

Ensure you have configured your AWS Credentials on your local computer using `aws configure` command and have enough access to deploy into AWS.

## Install Instructions

Before you deploy the changes, make sure you update `default` values in `vars-configs.tf` according to what you already have deployed in AWS.:

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

Please wait as all the infrastructure is deployed. Please refer to the `commands.tf` for a set of instructions that will provision the service, deployment and ingress (ALB) in the EKS Cluster.


## EKS Provisioning Commands ()

Terraform will automatically run these commands for your, but in case, below are a set of `aws`, `kubectl` commands that will interact with the cluster and apply the required configs to run a sample application:

```sh
# Get EKS Cluster Config (Needs AWS Credentials)
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster

# Create and Set Default Namespace
kubectl create namespace eks-sample-app
kubectl config set-context --current --namespace=eks-sample-app

# Apply Required Configs
kubectl apply -f ./configs/eks-deployment.yaml
kubectl apply -f ./configs/eks-service.yaml

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set vpcId={REPLACE_WITH_YOUR_VPC_ID} \
  --set serviceAccount.name=aws-load-balancer-controller

## Apply Ingress Config Until Successful
for i in {1..10}; do
	kubectl apply -f ./configs/eks-ingress.yaml && break || sleep 30
done

```

## Destroy Instruction

EKS will provision automatically an ALB, and this resource is not managed through Terraform.

Please execute the following commands to remove any left over infrastructure that was automatically created by EKS:

```sh
kubectl delete -f ./configs/eks-deployment.yaml   
kubectl delete -f ./configs/eks-service.yaml   
kubectl delete -f ./configs/eks-ingress.yaml
```

Then finalize with, 

```
terraform destroy
```
