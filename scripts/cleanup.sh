#!/bin/bash

# Cloud Webapp Cleanup Script
# Usage: ./scripts/cleanup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Starting cleanup of Cloud Webapp resources${NC}"

# Check if we're in the right directory
if [[ ! -f "app/main.py" ]]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Confirmation prompt
read -p "⚠️  This will destroy ALL AWS resources for this project. Are you sure? (yes/no): " confirmation

if [[ $confirmation != "yes" ]]; then
    echo -e "${YELLOW}🚫 Cleanup cancelled${NC}"
    exit 0
fi

# Step 1: Destroy app infrastructure
echo -e "\n${YELLOW}🏗️  Step 1: Destroying application infrastructure...${NC}"
cd infra/app

if [[ -f "terraform.tfstate" ]]; then
    terraform destroy -auto-approve
    echo -e "${GREEN}✅ Application infrastructure destroyed${NC}"
else
    echo -e "${YELLOW}⚠️  No application terraform state found, skipping...${NC}"
fi

# Step 2: Destroy base infrastructure
echo -e "\n${YELLOW}📋 Step 2: Destroying base infrastructure...${NC}"
cd ../base

if [[ -f "terraform.tfstate" ]]; then
    terraform destroy -auto-approve
    echo -e "${GREEN}✅ Base infrastructure destroyed${NC}"
else
    echo -e "${YELLOW}⚠️  No base terraform state found, skipping...${NC}"
fi

# Step 3: Clean up local Docker images (optional)
echo -e "\n${YELLOW}🐳 Step 3: Cleaning up local Docker images...${NC}"
cd ../../

# Remove local images
docker rmi cloud-webapp:latest 2>/dev/null || echo "Local cloud-webapp image not found"
docker rmi 361769574376.dkr.ecr.us-east-1.amazonaws.com/cloud-webapp:latest 2>/dev/null || echo "ECR image not found locally"
docker rmi 361769574376.dkr.ecr.us-east-1.amazonaws.com/cloud-webapp:v1-amd64 2>/dev/null || echo "ECR v1-amd64 image not found locally"

echo -e "${GREEN}✅ Local Docker images cleaned up${NC}"

# Step 4: Summary
echo -e "\n${GREEN}📋 Cleanup Summary:${NC}"
echo "• ECS Service and Task Definition: Destroyed"
echo "• ECS Cluster: Destroyed"
echo "• ECR Repository: Destroyed (including all images)"
echo "• VPC and associated resources: Destroyed"
echo "• IAM Roles: Destroyed"
echo "• CloudWatch Log Groups: Destroyed"
echo "• Local Docker images: Removed"

echo -e "\n${GREEN}🎉 Cleanup completed successfully!${NC}"
echo -e "${GREEN}💰 All AWS resources have been destroyed to avoid future charges.${NC}"
