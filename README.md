# Cloud Webapp Free Tier

A containerized FastAPI web application deployed on AWS ECS using Terraform, optimized for AWS Free Tier usage.

## Architecture

- **Application**: FastAPI running on Python 3.11
- **Container**: Docker with Uvicorn server
- **Infrastructure**: AWS ECS Fargate with VPC
- **Registry**: Amazon ECR for container images
- **IaC**: Terraform with modular structure

## Project Structure

```
cloud-webapp-free-tier/
├── app/
│   ├── main.py                    # FastAPI application
│   ├── requirements.txt           # Python dependencies  
│   ├── Dockerfile                 # Container configuration
│   └── task-definition-fixed.json # ECS task definition (manual)
├── infra/
│   ├── base/                      # Base infrastructure module
│   │   ├── main.tf               # VPC, ECR, Security Groups
│   │   ├── variables.tf          # Input variables
│   │   ├── outputs.tf            # Module outputs
│   │   └── terraform.tfvars      # Variable values
│   └── app/                       # Application infrastructure module
│       ├── main.tf               # ECS cluster, service, task definition
│       ├── variables.tf          # Input variables  
│       ├── outputs.tf            # Module outputs
│       └── terraform.tfvars      # Variable values
└── README.md
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Docker installed
- Terraform >= 1.0
- AWS Account ID: 361769574376

## Deployment Instructions

### 1. Deploy Base Infrastructure

```bash
cd infra/base
terraform init
terraform plan
terraform apply
```

### 2. Build and Push Docker Image

**Important**: Build for AMD64 architecture (required for ECS Fargate):

```bash
cd app

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 361769574376.dkr.ecr.us-east-1.amazonaws.com

# Build for correct architecture
docker build --platform linux/amd64 -t cloud-webapp .

# Tag and push
docker tag cloud-webapp:latest 361769574376.dkr.ecr.us-east-1.amazonaws.com/cloud-webapp:latest
docker push 361769574376.dkr.ecr.us-east-1.amazonaws.com/cloud-webapp:latest
```

### 3. Deploy Application Infrastructure

```bash
cd infra/app
terraform init
terraform plan
terraform apply
```

## Architecture Details

### Base Module
- **VPC**: 10.0.0.0/16 with DNS support
- **Public Subnet**: 10.0.1.0/24 in us-east-1a
- **Internet Gateway**: For public internet access
- **Security Group**: Allows HTTP (port 80) inbound traffic
- **ECR Repository**: Container image registry

### App Module  
- **ECS Cluster**: Fargate cluster for container orchestration
- **Task Definition**: Container specs (256 CPU, 512 MB memory)
- **ECS Service**: Manages desired container instances
- **CloudWatch Logs**: Application logging
- **IAM Role**: ECS task execution permissions

## Monitoring

View application logs:
```bash
aws logs tail /ecs/cloud-webapp-task --follow --region us-east-1
```

Check service status:
```bash
aws ecs describe-services --cluster cloud-webapp-cluster --services cloud-webapp-service --region us-east-1
```

## Troubleshooting

### Common Issues

1. **Container Architecture Mismatch**
   - **Error**: `exec format error`
   - **Solution**: Build with `--platform linux/amd64` flag

2. **Task Stopping with Exit Code 255**
   - Check CloudWatch logs for detailed error messages
   - Verify ECR image exists and is accessible

3. **No CloudWatch Logs**
   - Ensure ECS execution role has CloudWatch permissions
   - Verify log group exists or auto-creation is enabled

## Cost Optimization

This project is designed for AWS Free Tier:
- **ECS Fargate**: 20 GB-hours per month (free)
- **ECR**: 500 MB storage (free)
- **CloudWatch**: 5 GB logs ingestion (free)
- **VPC**: No additional charges for basic setup

## Cleanup

To avoid charges, destroy resources when done:

```bash
# Destroy app infrastructure first
cd infra/app
terraform destroy

# Then destroy base infrastructure
cd ../base
terraform destroy
```

## API Endpoints

- `GET /` - Returns `{"message": "Hello from ECS!"}`

## Development

Run locally:
```bash
cd app
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 80
```
