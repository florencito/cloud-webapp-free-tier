# Cloud Webapp Free Tier 🚀

[![Deploy to AWS](https://github.com/florencito/cloud-webapp-free-tier/actions/workflows/deploy.yml/badge.svg)](https://github.com/florencito/cloud-webapp-free-tier/actions/workflows/deploy.yml)

A **production-ready** containerized FastAPI web application with **secure CI/CD pipeline**, deployed on AWS ECS using Terraform and GitHub Actions. Features enterprise-grade security practices with AWS Secrets Manager and zero-hardcoded credentials.

## 🏗️ Architecture

- **Application**: FastAPI with PostgreSQL database connectivity
- **Container**: Docker with multi-architecture support (AMD64)
- **Infrastructure**: AWS ECS Fargate with private RDS in VPC
- **Security**: AWS Secrets Manager for credential management
- **CI/CD**: GitHub Actions with automated testing
- **IaC**: Terraform with remote state management
- **Registry**: Amazon ECR for container images

## 📁 Project Structure

```
cloud-webapp-free-tier/
├── .github/workflows/             # GitHub Actions CI/CD
│   ├── deploy.yml                # Automated deployment pipeline
│   └── cleanup.yml               # Resource cleanup workflow
├── app/
│   ├── main.py                   # FastAPI app with database integration
│   ├── requirements.txt          # Python dependencies (no secrets)
│   ├── Dockerfile                # Multi-stage container build
│   └── .dockerignore             # Docker build exclusions
├── infra/
│   ├── remote-state/             # 🆕 Terraform state backend
│   │   └── main.tf               # S3 + DynamoDB for state management
│   ├── base/                     # Base infrastructure module
│   │   ├── main.tf               # VPC, RDS, ECR, Secrets Manager
│   │   ├── variables.tf          # Input variables
│   │   ├── outputs.tf            # Secure outputs (no passwords)
│   │   └── backend.tf            # 🆕 S3 remote state configuration
│   └── app/                      # Application infrastructure
│       ├── main.tf               # ECS with IAM roles & policies
│       ├── variables.tf          # Input variables
│       ├── outputs.tf            # Service information
│       └── backend.tf            # 🆕 S3 remote state configuration
├── scripts/
│   ├── setup-remote-state.sh     # 🆕 Automated state backend setup
│   ├── deploy.sh                 # Manual deployment script
│   └── test-db-local.py          # 🆕 Local database testing utility
├── docs/
│   └── GITHUB_ACTIONS.md         # 🆕 Complete CI/CD documentation
└── README.md                     # This comprehensive guide
```

## 🔧 Prerequisites

### Required Tools
- **AWS CLI** configured with appropriate credentials
- **Docker** installed and running
- **Terraform** >= 1.0
- **Git** for version control
- **Python 3.11+** for local development

### AWS Setup
- **AWS Account ID**: 361769574376
- **GitHub OIDC Role**: `GitHubActionsDeployRole` (configured)
- **IAM Permissions**: ECS, RDS, ECR, Secrets Manager, VPC management

## 🚀 Deployment Options

### Option 1: GitHub Actions CI/CD (Recommended)

**Automatic Deployment:**
```bash
git push origin main
```

**Manual Deployment:**
1. Go to GitHub → Actions tab
2. Select "Deploy to AWS" workflow
3. Click "Run workflow"

**What it does:**
- ✅ Deploys secure infrastructure (VPC, RDS, ECR, Secrets Manager)
- ✅ Builds and pushes Docker image automatically
- ✅ Creates ECS cluster with proper IAM roles
- ✅ Tests application endpoints
- ✅ Provides live application URLs

### Option 2: Manual Deployment

**1. Setup Remote State Backend (First Time Only):**
```bash
./scripts/setup-remote-state.sh
```

**2. Deploy via Script:**
```bash
./scripts/deploy.sh
```

**3. Manual Step-by-Step:**
```bash
# Deploy base infrastructure
cd infra/base
terraform init
terraform apply -auto-approve

# Build and push image
cd ../../app
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 361769574376.dkr.ecr.us-east-1.amazonaws.com
docker build --platform linux/amd64 -t cloud-webapp .
docker tag cloud-webapp:latest 361769574376.dkr.ecr.us-east-1.amazonaws.com/cloud-webapp:latest
docker push 361769574376.dkr.ecr.us-east-1.amazonaws.com/cloud-webapp:latest

# Deploy application
cd ../infra/app
terraform init
terraform apply -auto-approve
```

## 🏛️ Architecture Details

### 🔐 Security Features
- **Zero Hardcoded Credentials**: All secrets managed via AWS Secrets Manager
- **Private Database**: RDS in private subnets (no public access)
- **Auto-Generated Passwords**: Random 16-character passwords with Terraform
- **Encrypted Storage**: All secrets encrypted at rest with AES256
- **IAM Least Privilege**: Minimal required permissions for each service
- **Network Isolation**: Separate public/private subnets with security groups

### 🏗️ Infrastructure Components

**Base Module (`infra/base/`):**
- **VPC**: 10.0.0.0/16 with DNS support and hostnames
- **Public Subnet**: 10.0.1.0/24 in us-east-1a (for ECS tasks)
- **Private Subnets**: 10.0.2.0/24 & 10.0.3.0/24 (for RDS)
- **NAT Gateway**: Secure internet access for private subnets
- **Internet Gateway**: Public internet access
- **RDS PostgreSQL**: db.t3.micro with automated backups
- **Secrets Manager**: Encrypted credential storage
- **ECR Repository**: Container image registry with AES256 encryption
- **Security Groups**: Restrictive rules (ECS → RDS, Internet → ECS)

**App Module (`infra/app/`):**
- **ECS Cluster**: Fargate cluster for serverless containers
- **Task Definition**: 256 CPU, 512 MB memory with secrets injection
- **ECS Service**: Auto-scaling service with health checks
- **IAM Roles**: Task execution + secrets access permissions
- **CloudWatch Logs**: Centralized application logging
- **Load Balancing**: Built-in ECS service discovery

**Remote State (`infra/remote-state/`):**
- **S3 Bucket**: Encrypted, versioned Terraform state storage
- **DynamoDB Table**: State locking for concurrent access prevention
- **Cross-Region Replication**: State backup and disaster recovery

## 📊 Monitoring & Testing

### Application Endpoints
- **Main App**: `http://[PUBLIC_IP]/` → `{"message": "Hello from ECS!"}`
- **Database Check**: `http://[PUBLIC_IP]/db-check` → `{"db": "connected", "host": "..."}`

### Monitoring Commands
```bash
# View real-time application logs
aws logs tail /ecs/cloud-webapp-task --follow --region us-east-1

# Check ECS service health
aws ecs describe-services --cluster cloud-webapp-cluster --services cloud-webapp-service --region us-east-1

# Get public IP of running task
TASK_ARN=$(aws ecs list-tasks --cluster cloud-webapp-cluster --service-name cloud-webapp-service --query 'taskArns[0]' --output text --region us-east-1)
ENI_ID=$(aws ecs describe-tasks --cluster cloud-webapp-cluster --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text --region us-east-1)
aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query 'NetworkInterfaces[0].Association.PublicIp' --output text --region us-east-1
```

### Local Database Testing
```bash
# Test database connection using Secrets Manager
python3 scripts/test-db-local.py [SECRET_ARN]
```

## 🔧 Troubleshooting

### Common Issues & Solutions

1. **Secrets Manager Conflict**
   - **Error**: `secret with this name is already scheduled for deletion`
   - **Solution**: Force delete existing secret:
     ```bash
     aws secretsmanager delete-secret --secret-id webapp/rds/credentials --force-delete-without-recovery --region us-east-1
     ```

2. **Docker Repository Format Error**
   - **Error**: `":latest" is not a valid repository/tag`
   - **Solution**: ECR URL construction issue - fixed in GitHub Actions workflow

3. **Container Architecture Mismatch**
   - **Error**: `exec format error`
   - **Solution**: Always build with `--platform linux/amd64` flag

4. **Database Connection Issues**
   - **Error**: Connection timeouts or authentication failures
   - **Solution**: Check security groups, verify secrets in AWS console

5. **ECS Tasks Not Starting**
   - Check CloudWatch logs for detailed error messages
   - Verify IAM permissions for task execution role
   - Ensure ECR image exists and is accessible

6. **Terraform State Conflicts**
   - **Error**: State locking or concurrent modifications
   - **Solution**: Remote state with DynamoDB handles this automatically

### Debug Commands
```bash
# Check ECS service events
aws ecs describe-services --cluster cloud-webapp-cluster --services cloud-webapp-service --region us-east-1 --query 'services[0].events[:5]'

# View stopped tasks for debugging
aws ecs list-tasks --cluster cloud-webapp-cluster --desired-status STOPPED --region us-east-1

# Check secret value (for debugging only)
aws secretsmanager get-secret-value --secret-id webapp/rds/credentials --region us-east-1
```

## 💰 Cost Optimization

### AWS Free Tier Eligible Resources
- **RDS PostgreSQL**: 750 hours/month db.t3.micro (free for 12 months)
- **ECS Fargate**: 20 GB-hours per month (always free)
- **ECR**: 500 MB storage per month (always free)
- **CloudWatch**: 5 GB logs ingestion (always free)
- **Secrets Manager**: 30-day free trial, then ~$0.40/month
- **VPC**: No charges for basic networking
- **NAT Gateway**: ~$0.045/hour (~$32/month - not free tier)

### Cost-Saving Strategies
1. **Use Cleanup Workflows**: Destroy resources when not in use
2. **Automated Teardown**: Run cleanup after presentations/demos
3. **Remote State Management**: Only ~$0.03/month for S3 + DynamoDB
4. **On-Demand Deployment**: Deploy only when needed, cleanup immediately after

### Academic/Demo Usage
```bash
# Cost-effective workflow for presentations:
# 1. Deploy before demo
git push origin main

# 2. Present application
# 3. Cleanup after demo  
# Go to Actions → "Cleanup AWS Resources" → Type "destroy" → Run

# 4. Optional: Remove remote state overnight
cd infra/remote-state && terraform destroy -auto-approve
```

## 🧹 Cleanup Options

### Option 1: GitHub Actions (Recommended)
1. Go to **GitHub → Actions** tab
2. Select **"Cleanup AWS Resources"**
3. Click **"Run workflow"**
4. Type exactly: **`destroy`**
5. Click **"Run workflow"**

**What it destroys:**
- ✅ ECS Service and Tasks (graceful shutdown)
- ✅ RDS Database Instance
- ✅ ECR Repository and Images
- ✅ VPC, Subnets, and Networking
- ✅ Security Groups and IAM Roles
- ✅ AWS Secrets Manager Secrets (force deleted)
- ⚠️ **Preserves**: S3 bucket and DynamoDB table for future deployments

### Option 2: Manual Cleanup
```bash
# Full cleanup (including remote state)
./scripts/cleanup-all.sh

# Or step by step:
cd infra/app && terraform destroy -auto-approve
cd ../base && terraform destroy -auto-approve
cd ../remote-state && terraform destroy -auto-approve  # Optional for cost savings
```

## 🔗 API Endpoints

| Endpoint | Method | Response | Purpose |
|----------|--------|----------|----------|
| `/` | GET | `{"message": "Hello from ECS!"}` | Health check |
| `/db-check` | GET | `{"db": "connected", "host": "..."}` | Database connectivity test |

## 👨‍💻 Development

### Local Development
```bash
cd app
pip install -r requirements.txt
# Note: Database features require AWS credentials for Secrets Manager
uvicorn main:app --host 0.0.0.0 --port 80 --reload
```

### Testing
```bash
# Test endpoints locally
curl http://localhost:80/
curl http://localhost:80/db-check

# Test with deployed application
curl http://[ECS_PUBLIC_IP]/
curl http://[ECS_PUBLIC_IP]/db-check
```

## 📚 Additional Resources

- **[GitHub Actions Documentation](docs/GITHUB_ACTIONS.md)** - Complete CI/CD guide
- **[AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)**
- **[Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)**
- **[FastAPI Documentation](https://fastapi.tiangolo.com/)**

## 🏆 Features Implemented

- ✅ **Secure CI/CD Pipeline** with GitHub Actions
- ✅ **Zero Hardcoded Secrets** (AWS Secrets Manager integration)
- ✅ **Production-Ready Architecture** (private RDS, VPC, security groups)
- ✅ **Infrastructure as Code** (Terraform with remote state)
- ✅ **Automated Testing** and deployment verification
- ✅ **Cost-Optimized** cleanup workflows
- ✅ **Multi-Architecture Docker** builds (AMD64 support)
- ✅ **Comprehensive Monitoring** (CloudWatch logs, health checks)
- ✅ **Enterprise Security** practices (IAM least privilege, encryption)

---

**Built with ❤️ for academic presentations and enterprise-ready deployments!**
