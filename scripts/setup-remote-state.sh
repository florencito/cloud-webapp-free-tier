#!/bin/bash

# Setup Terraform Remote State Backend
# This script creates S3 bucket and DynamoDB table for Terraform state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Terraform Remote State Backend${NC}"

# Check if we're in the right directory
if [[ ! -f "scripts/setup-remote-state.sh" ]]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Step 1: Create the remote state infrastructure
echo -e "\n${YELLOW}📋 Step 1: Creating S3 bucket and DynamoDB table for state management...${NC}"
cd infra/remote-state

# Initialize and apply the remote state infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# Get the outputs
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

echo -e "${GREEN}✅ Remote state infrastructure created successfully!${NC}"
echo -e "${GREEN}📦 S3 Bucket: $BUCKET_NAME${NC}"
echo -e "${GREEN}🔐 DynamoDB Table: $DYNAMODB_TABLE${NC}"

# Step 2: Update backend configurations
echo -e "\n${YELLOW}📋 Step 2: Updating backend configurations...${NC}"

cd ../../

# Create backend configuration for base infrastructure
cat > infra/base/backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "base/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

# Create backend configuration for app infrastructure
cat > infra/app/backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo -e "${GREEN}✅ Backend configurations created!${NC}"

# Step 3: Migrate existing state to S3
echo -e "\n${YELLOW}📋 Step 3: Migrating existing state to S3 backend...${NC}"

# Migrate base state
echo -e "${YELLOW}Migrating base infrastructure state...${NC}"
cd infra/base
terraform init -migrate-state -force-copy
echo -e "${GREEN}✅ Base state migrated${NC}"

# Migrate app state
echo -e "${YELLOW}Migrating app infrastructure state...${NC}"
cd ../app
terraform init -migrate-state -force-copy
echo -e "${GREEN}✅ App state migrated${NC}"

cd ../../

echo -e "\n${GREEN}🎉 Remote state setup completed successfully!${NC}"
echo -e "\n${BLUE}📋 Summary:${NC}"
echo -e "• S3 Bucket: $BUCKET_NAME"
echo -e "• DynamoDB Table: $DYNAMODB_TABLE"
echo -e "• Base state key: base/terraform.tfstate"
echo -e "• App state key: app/terraform.tfstate"

echo -e "\n${YELLOW}📝 Next Steps:${NC}"
echo -e "1. Commit the new backend.tf files to git"
echo -e "2. Your GitHub Actions will now work with persistent state"
echo -e "3. You can safely run deploy and cleanup actions"

echo -e "\n${YELLOW}💡 Important Notes:${NC}"
echo -e "• The S3 bucket and DynamoDB table are persistent"
echo -e "• Multiple team members can now collaborate safely"
echo -e "• State locking prevents concurrent modifications"
echo -e "• All state changes are encrypted and versioned"
