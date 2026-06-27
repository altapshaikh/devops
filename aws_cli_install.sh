#!/bin/bash

# Enhanced script to install AWS CLI v2, kubectl, and eksctl
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check OS compatibility
check_os() {
    if [[ ! "$OSTYPE" =~ ^linux ]]; then
        print_error "This script is only compatible with Linux systems"
        exit 1
    fi
    print_info "Running on: $(uname -s) $(uname -m)"
}

# Trap errors with better context
trap 'print_error "Script failed at line $LINENO"; exit 1' ERR

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    print_warning "This script requires sudo access. You may be prompted for your password."
fi

# Check OS compatibility
check_os

# Update system packages
print_header "Updating system packages"
sudo apt update -y
sudo apt upgrade -y
print_success "System packages updated"

# Install dependencies
print_header "Installing dependencies"
sudo apt install -y curl unzip git jq
print_success "Dependencies installed"

# Install AWS CLI v2
print_header "Installing AWS CLI v2"
if command_exists aws; then
    AWS_VERSION=$(aws --version)
    print_warning "AWS CLI already installed: $AWS_VERSION"
    read -p "Do you want to update? (yes/no): " update_aws
    if [[ "$update_aws" =~ ^[Yy][Ee][Ss]$ ]]; then
        print_header "Updating AWS CLI v2"
        cd /tmp
        curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || {
            print_error "Failed to download AWS CLI"
            exit 1
        }
        unzip -o awscliv2.zip
        sudo ./aws/install --update
        rm -rf awscliv2.zip aws/
    fi
else
    cd /tmp
    curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || {
        print_error "Failed to download AWS CLI"
        exit 1
    }
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
fi
AWS_VERSION=$(aws --version)
print_success "AWS CLI installed: $AWS_VERSION"

# Install kubectl
print_header "Installing kubectl v1.31.0"
KUBECTL_VERSION="v1.31.0"
if command_exists kubectl; then
    CURRENT_VERSION=$(kubectl version --client -o json 2>/dev/null | jq -r '.gitVersion' || echo "unknown")
    print_warning "kubectl already installed: $CURRENT_VERSION"
    read -p "Do you want to update? (yes/no): " update_kubectl
    if [[ "$update_kubectl" =~ ^[Yy][Ee][Ss]$ ]]; then
        cd /tmp
        curl -fLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" || {
            print_error "Failed to download kubectl"
            exit 1
        }
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
    fi
else
    cd /tmp
    curl -fLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" || {
        print_error "Failed to download kubectl"
        exit 1
    }
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
fi

KUBECTL_VERSION_INSTALLED=$(kubectl version --client -o json | jq -r '.gitVersion')
print_success "kubectl installed: $KUBECTL_VERSION_INSTALLED"

# Install eksctl
print_header "Installing eksctl"
if command_exists eksctl; then
    EKSCTL_VERSION=$(eksctl version)
    print_warning "eksctl already installed: $EKSCTL_VERSION"
    read -p "Do you want to update? (yes/no): " update_eksctl
    if [[ "$update_eksctl" =~ ^[Yy][Ee][Ss]$ ]]; then
        cd /tmp
        ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
        PLATFORM=$(uname -s)_$ARCH
        
        curl -fLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" || {
            print_error "Failed to download eksctl"
            exit 1
        }
        
        tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp || {
            print_error "Failed to extract eksctl archive"
            rm -f eksctl_$PLATFORM.tar.gz
            exit 1
        }
        
        rm -f eksctl_$PLATFORM.tar.gz
        sudo install -m 0755 /tmp/eksctl /usr/local/bin || {
            print_error "Failed to install eksctl to /usr/local/bin"
            exit 1
        }
        rm -f /tmp/eksctl
    fi
else
    cd /tmp
    ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
    PLATFORM=$(uname -s)_$ARCH
    
    curl -fLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" || {
        print_error "Failed to download eksctl"
        exit 1
    }
    
    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp || {
        print_error "Failed to extract eksctl archive"
        rm -f eksctl_$PLATFORM.tar.gz
        exit 1
    }
    
    rm -f eksctl_$PLATFORM.tar.gz
    sudo install -m 0755 /tmp/eksctl /usr/local/bin || {
        print_error "Failed to install eksctl to /usr/local/bin"
        exit 1
    }
    rm -f /tmp/eksctl
fi

EKSCTL_VERSION=$(eksctl version)
print_success "eksctl installed: $EKSCTL_VERSION"

# Function to configure AWS CLI
configure_aws_cli() {
    echo ""
    echo -e "${YELLOW}Please provide your AWS credentials:${NC}"
    echo ""
    
    read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
    read -sp "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo ""
    read -p "Default region (e.g., us-east-1): " AWS_DEFAULT_REGION
    read -p "Default output format (json/yaml/table/text) [default: json]: " AWS_DEFAULT_OUTPUT
    AWS_DEFAULT_OUTPUT=${AWS_DEFAULT_OUTPUT:-json}
    
    # Validate inputs
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ]; then
        print_error "Missing required AWS credentials"
        return 1
    fi
    
    # Configure AWS CLI
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set region "$AWS_DEFAULT_REGION"
    aws configure set output "$AWS_DEFAULT_OUTPUT"
    
    print_success "AWS CLI configured successfully"
    
    # Verify configuration
    echo ""
    print_header "AWS Configuration Verification"
    if aws sts get-caller-identity &>/dev/null; then
        echo ""
        aws sts get-caller-identity
        echo ""
        print_success "AWS credentials are valid!"
    else
        print_error "Failed to verify AWS credentials. Please check your credentials."
        return 1
    fi
}

# Configure AWS CLI
print_header "AWS CLI Configuration"
if [ -f ~/.aws/credentials ]; then
    print_warning "AWS credentials file already exists at ~/.aws/credentials"
    read -p "Do you want to reconfigure AWS CLI? (yes/no): " reconfigure_choice
    if [[ "$reconfigure_choice" =~ ^[Yy][Ee][Ss]$ ]]; then
        configure_aws_cli
    else
        print_info "Skipping AWS CLI configuration"
    fi
else
    read -p "Do you want to configure AWS CLI now? (yes/no): " configure_choice
    if [[ "$configure_choice" =~ ^[Yy][Ee][Ss]$ ]]; then
        configure_aws_cli
    else
        print_info "Skipping AWS CLI configuration"
    fi
fi

# Verify all installations
print_header "Verification Summary"
echo ""
echo "AWS CLI:"
aws --version
echo ""
echo "kubectl:"
kubectl version --client
echo ""
echo "eksctl:"
eksctl version
echo ""

print_success "All tools installed successfully!"
print_header "Installation Complete"
echo -e "${GREEN}You can now use AWS CLI, kubectl, and eksctl commands${NC}"
echo ""
print_info "Next steps:"
echo -e "${GREEN}  • AWS CLI: aws configure or use AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION env vars${NC}"
echo -e "${GREEN}  • kubectl: kubectl get nodes${NC}"
echo -e "${GREEN}  • eksctl: eksctl get clusters${NC}"
