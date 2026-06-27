#!/bin/bash

# Script to create an AWS EKS cluster
# Exit on error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Trap errors with better context
trap 'print_error "Cluster creation failed at line $LINENO"; exit 1' ERR

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    print_error "eksctl is not installed. Please run aws_cli_install.sh first."
    exit 1
fi

# Cluster configuration
CLUSTER_NAME="${1:-demo-cluster}"
AWS_REGION="${2:-ap-south-1}"
NODE_TYPE="${3:-t3.medium}"
NUM_NODES="${4:-2}"
NODEGROUP_NAME="workers"

# Display configuration
print_header "EKS Cluster Creation Configuration"
echo -e "${BLUE}Cluster Name:${NC} $CLUSTER_NAME"
echo -e "${BLUE}Region:${NC} $AWS_REGION"
echo -e "${BLUE}Node Type:${NC} $NODE_TYPE"
echo -e "${BLUE}Number of Nodes:${NC} $NUM_NODES"
echo -e "${BLUE}Node Group Name:${NC} $NODEGROUP_NAME"
echo ""

# Confirm before proceeding
read -p "Do you want to proceed with cluster creation? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    print_warning "Cluster creation cancelled"
    exit 0
fi

# Create the cluster
print_header "Creating EKS Cluster"
print_info "This may take 10-15 minutes. Please wait..."
echo ""

eksctl create cluster \
--name "$CLUSTER_NAME" \
--region "$AWS_REGION" \
--nodegroup-name "$NODEGROUP_NAME" \
--node-type "$NODE_TYPE" \
--nodes "$NUM_NODES" \
--managed

if [ $? -eq 0 ]; then
    print_success "EKS Cluster created successfully!"
    echo ""
    print_header "Cluster Details"
    echo -e "${GREEN}Cluster Name: $CLUSTER_NAME${NC}"
    echo -e "${GREEN}Region: $AWS_REGION${NC}"
    echo -e "${GREEN}Node Type: $NODE_TYPE${NC}"
    echo -e "${GREEN}Number of Nodes: $NUM_NODES${NC}"
    echo ""
    print_info "Next steps:"
    echo -e "${GREEN}  1. Update kubeconfig: aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME${NC}"
    echo -e "${GREEN}  2. Verify cluster: kubectl get nodes${NC}"
    echo -e "${GREEN}  3. Deploy applications: kubectl apply -f <your-manifest.yaml>${NC}"
    echo ""
    print_info "To delete the cluster later, run: ./delete-cluster.sh $CLUSTER_NAME $AWS_REGION"
else
    print_error "Failed to create EKS cluster"
    exit 1
fi
