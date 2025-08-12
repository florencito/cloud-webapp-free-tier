#!/bin/bash

# Cloud Webapp Deployment Script
# Usage: ./scripts/deploy.sh

set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="361769574376"
ECR_REPO="cloud-webapp"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment of Cloud Webapp${NC}"

# Check if we're in the right directory
if [[ ! -f "app/main.py" ]]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Step 1: Deploy base infrastructure
echo -e "\n${YELLOW}📋 Step 1: Deploying base infrastructure...${NC}"
cd infra/base
terraform init
terraform plan
terraform apply -auto-approve

# Get ECR URL from Terraform output
ECR_URL=$(terraform output -raw ecr_repository_url)
echo -e "${GREEN}✅ Base infrastructure deployed. ECR URL: $ECR_URL${NC}"

# Step 2: Build and push Docker image
echo -e "\n${YELLOW}🐳 Step 2: Building and pushing Docker image...${NC}"
cd ../../app

# ECR login
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# Build image for AMD64 (ECS Fargate requirement)
echo "Building Docker image for AMD64 architecture..."
docker build --platform linux/amd64 -t $ECR_REPO .

# Tag and push
echo "Tagging and pushing image..."
docker tag $ECR_REPO:latest $ECR_URL:$IMAGE_TAG
docker push $ECR_URL:$IMAGE_TAG

echo -e "${GREEN}✅ Docker image pushed successfully${NC}"

# Step 3: Deploy app infrastructure
echo -e "\n${YELLOW}🏗️  Step 3: Deploying application infrastructure...${NC}"
cd ../infra/app
terraform init
terraform plan
terraform apply -auto-approve

# Get service information
CLUSTER_NAME=$(terraform output -raw ecs_service_name)
echo -e "${GREEN}✅ Application infrastructure deployed${NC}"

# Step 4: Verify deployment
echo -e "\n${YELLOW}🔍 Step 4: Verifying deployment...${NC}"
echo "Waiting for service to stabilize..."
aws ecs wait services-stable --cluster cloud-webapp-cluster --services cloud-webapp-service --region $AWS_REGION

# Get service status
RUNNING_COUNT=$(aws ecs describe-services --cluster cloud-webapp-cluster --services cloud-webapp-service --region $AWS_REGION --query 'services[0].runningCount')
DESIRED_COUNT=$(aws ecs describe-services --cluster cloud-webapp-cluster --services cloud-webapp-service --region $AWS_REGION --query 'services[0].desiredCount')

if [[ $RUNNING_COUNT -eq $DESIRED_COUNT ]]; then
    echo -e "${GREEN}✅ Deployment successful! Service is running with $RUNNING_COUNT/$DESIRED_COUNT tasks${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Service has $RUNNING_COUNT/$DESIRED_COUNT tasks running${NC}"
fi

# Display useful information
echo -e "\n${GREEN}📋 Deployment Summary:${NC}"
echo "• Cluster: cloud-webapp-cluster"
echo "• Service: cloud-webapp-service" 
echo "• Image: $ECR_URL:$IMAGE_TAG"
echo "• Region: $AWS_REGION"

echo -e "\n${YELLOW}📊 View logs:${NC}"
echo "aws logs tail /ecs/cloud-webapp-task --follow --region $AWS_REGION"

echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
