🚀 AWS EKS Cluster Setup from EC2 (Complete Step-by-Step Guide)

This repository provides a complete hands-on guide to create an AWS EKS cluster from an EC2 instance using command-line tools.

🎯 Covers:

EC2 preparation

AWS CLI installation

kubectl installation

eksctl installation

EKS cluster creation

kubeconfig setup

Cluster validation

Cleanup

📌 Architecture Overview
Local Laptop
     |
     | SSH
     ▼
EC2 Instance (Amazon Linux)
     |
     | AWS CLI + kubectl + eksctl
     ▼
AWS EKS Control Plane
     |
     | Kubernetes API
     ▼
Worker Nodes (EC2 Managed Nodes)

🛠️ Tech Stack

AWS EC2

AWS EKS

kubectl

eksctl

AWS CLI

Linux (Amazon Linux)

✅ Prerequisites
🔹 AWS Account

Active AWS account

IAM user with programmatic access

🔹 EC2 Instance Setup

Launch EC2 instance with:

Property	Value
AMI	Amazon Linux 2 / Amazon Linux 2023
Instance Type	t3.medium or higher
Storage	Minimum 20 GB
Security Group	Allow SSH (22)
IAM Role	AdministratorAccess (for demo)
🔐 Step 1 — Connect to EC2
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>


Verify OS:

cat /etc/os-release

🛠️ Step 2 — Update System
sudo yum update -y
sudo yum install unzip curl -y

☁️ Step 3 — Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


Verify:

aws --version

🔑 Step 4 — Configure AWS Credentials
aws configure


Provide:

AWS Access Key ID
AWS Secret Access Key
Default region name  (ex: ap-south-1)
Default output format (json)


Validate:

aws sts get-caller-identity

☸️ Step 5 — Install kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/


Verify:

kubectl version --client

⚙️ Step 6 — Install eksctl
curl -sLO https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz
tar -xzf eksctl_Linux_amd64.tar.gz
sudo mv eksctl /usr/local/bin/


Verify:

eksctl version

🚀 Step 7 — Create EKS Cluster
eksctl create cluster \
--name altap-eks \
--region ap-south-1 \
--nodegroup-name worker-nodes \
--node-type t3.medium \
--nodes 2 \
--managed


⏳ Cluster creation takes around 15–20 minutes.

🔍 Step 8 — Configure kubeconfig

Usually auto-configured. If not:

aws eks update-kubeconfig --region ap-south-1 --name altap-eks


Validate cluster access:

kubectl get nodes
kubectl get pods -A

📊 Step 9 — Cluster Validation

Check cluster info:

kubectl cluster-info


Check namespaces:

kubectl get ns


Check system pods:

kubectl get pods -n kube-system

💰 Step 10 — Cost Monitoring

Check resources created:

EC2 instances

Load balancers

VPC

EBS volumes

Use AWS Billing Dashboard.

🧹 Step 11 — Cleanup (Mandatory)

To avoid billing:

eksctl delete cluster --name altap-eks --region ap-south-1


Verify deletion from AWS Console.

📂 Repository Structure
eks-setup-from-ec2/
 └── README.md
