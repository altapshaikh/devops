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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
print_header "Updating system packages"
sudo apt update -y
sudo apt upgrade -y
print_success "System packages updated"

# Install dependencies
print_header "Installing dependencies"
sudo apt install -y curl unzip git
print_success "Dependencies installed"

# Install AWS CLI v2
print_header "Installing AWS CLI v2"
if command_exists aws; then
    AWS_VERSION=$(aws --version)
    print_warning "AWS CLI already installed: $AWS_VERSION"
    print_header "Updating AWS CLI v2"
    cd /tmp
    curl -f "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o awscliv2.zip
    sudo ./aws/install --update
    rm -rf awscliv2.zip aws/
else
    cd /tmp
    curl -f "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
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
    CURRENT_VERSION=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    print_warning "kubectl already installed: $CURRENT_VERSION"
fi

cd /tmp
curl -fLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

KUBECTL_VERSION_INSTALLED=$(kubectl version --client -o json | grep -o '"gitVersion":"[^"]*"' | cut -d'"' -f4)
print_success "kubectl installed: $KUBECTL_VERSION_INSTALLED"

# Install eksctl
print_header "Installing eksctl"
if command_exists eksctl; then
    EKSCTL_VERSION=$(eksctl version)
    print_warning "eksctl already installed: $EKSCTL_VERSION"
else
    cd /tmp
    # for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
    ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
    PLATFORM=$(uname -s)_$ARCH
    
    if ! curl -fLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"; then
        print_error "Failed to download eksctl"
        exit 1
    fi
    
    # (Optional) Verify checksum
    if ! curl -fL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check; then
        print_warning "Checksum verification skipped or failed, proceeding with installation"
    fi
    
    if ! tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp; then
        print_error "Failed to extract eksctl archive"
        rm -f eksctl_$PLATFORM.tar.gz
        exit 1
    fi
    
    rm -f eksctl_$PLATFORM.tar.gz
    
    if ! sudo install -m 0755 /tmp/eksctl /usr/local/bin; then
        print_error "Failed to install eksctl to /usr/local/bin"
        exit 1
    fi
    
    rm -f /tmp/eksctl
fi

EKSCTL_VERSION=$(eksctl version)
print_success "eksctl installed: $EKSCTL_VERSION"

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
