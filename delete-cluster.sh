#!/bin/bash

# Script to delete an AWS EKS cluster
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
trap 'print_error "Cluster deletion failed at line $LINENO"; exit 1' ERR

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    print_error "eksctl is not installed. Please install eksctl first: https://eksctl.io/"
    exit 1
fi

# Cluster configuration
CLUSTER_NAME="${1:-demo-cluster}"
AWS_REGION="${2:-ap-south-1}"

# Display configuration
print_header "EKS Cluster Deletion Configuration"
echo -e "${BLUE}Cluster Name:${NC} $CLUSTER_NAME"
echo -e "${BLUE}Region:${NC} $AWS_REGION"
echo ""

# Confirm before proceeding
print_warning "WARNING: This will permanently delete the EKS cluster and all associated resources (nodegroups, load balancers, etc)."
read -p "Do you want to proceed with cluster deletion? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    print_warning "Cluster deletion cancelled"
    exit 0
fi

# Delete the cluster
print_header "Deleting EKS Cluster"
print_info "This may take several minutes. Please wait..."
echo ""

eksctl delete cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION"

if [ $? -eq 0 ]; then
    print_success "EKS Cluster deleted successfully!"
    echo ""
    print_header "Post-deletion details"
    echo -e "${GREEN}Cluster Name: $CLUSTER_NAME${NC}"
    echo -e "${GREEN}Region: $AWS_REGION${NC}"
    echo ""
    print_info "Next steps you may want to run manually:"
    echo -e "${GREEN}  1. Remove kubeconfig context if present: kubectl config delete-context arn:aws:eks:$AWS_REGION:*:cluster/$CLUSTER_NAME || true${NC}"
    echo -e "${GREEN}  2. Remove cluster entry from kubeconfig: kubectl config delete-cluster $CLUSTER_NAME || true${NC}"
    echo -e "${GREEN}  3. Verify AWS resources: Check for leftover VPCs, load balancers, security groups, or CloudFormation stacks in the AWS Console.${NC}"
    echo ""
else
    print_error "Failed to delete EKS cluster"
    exit 1
fi
