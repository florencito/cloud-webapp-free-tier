# GitHub Actions CI/CD Documentation

This project uses GitHub Actions for automated deployment and cleanup of the cloud web application infrastructure.

## 🔄 Workflows

### 1. Deploy to AWS (`deploy.yml`)

**Trigger:** Automatically runs on push to `main` branch, or manually via workflow dispatch.

**What it does:**
- Deploys base infrastructure (VPC, RDS, ECR, Secrets Manager)
- Builds and pushes Docker image to ECR
- Deploys ECS application infrastructure
- Tests the deployed application
- Provides deployment summary with URLs

**Jobs:**
1. **deploy-base-infrastructure** - Creates VPC, RDS, ECR, etc.
2. **build-and-push-image** - Builds Docker image and pushes to ECR
3. **deploy-app-infrastructure** - Creates ECS cluster, service, tasks

### 2. Cleanup AWS Resources (`cleanup.yml`)

**Trigger:** Manual workflow dispatch only (for safety)

**What it does:**
- Gracefully stops ECS service
- Destroys all AWS resources
- Cleans up ECR images
- Preserves Terraform state backend

**Safety Features:**
- Requires typing "destroy" to confirm
- Protection job prevents accidental runs
- Graceful shutdown of services

## 🏗️ Infrastructure Components

### Remote State Backend
- **S3 Bucket:** `cloud-webapp-free-tier-terraform-state-e652a150fd6fe784`
- **DynamoDB Table:** `cloud-webapp-free-tier-terraform-locks`
- **Encryption:** AES256 encryption at rest
- **Versioning:** Enabled for state file recovery
- **State Locking:** Prevents concurrent modifications

### Deployed Resources
- **VPC:** Custom VPC with public/private subnets
- **RDS:** PostgreSQL database in private subnets
- **ECS:** Fargate cluster with auto-scaling
- **ECR:** Docker image registry
- **Secrets Manager:** Database credentials
- **IAM:** Roles and policies with least privilege

## 🚀 Usage

### Deploy Application

#### Automatic (Recommended)
```bash
# Push to main branch
git push origin main
```

#### Manual
1. Go to GitHub Actions tab
2. Select "Deploy to AWS" workflow
3. Click "Run workflow"

### Cleanup Resources

⚠️ **Warning:** This will destroy all AWS resources!

1. Go to GitHub Actions tab
2. Select "Cleanup AWS Resources" workflow
3. Click "Run workflow"
4. Type **exactly** `destroy` in the confirmation field
5. Click "Run workflow"

## 📊 Monitoring

### Deployment Status
- Check GitHub Actions tab for workflow status
- View deployment logs and summaries
- Get application URLs from workflow output

### Application Health
After deployment, the workflow provides:
- **Main App URL:** `http://[PUBLIC_IP]/`
- **Database Check:** `http://[PUBLIC_IP]/db-check`

### AWS Console Monitoring
- **ECS Console:** Monitor service health and logs
- **CloudWatch Logs:** `/ecs/cloud-webapp-task`
- **RDS Console:** Database performance and metrics

## 🔧 Troubleshooting

### Common Issues

1. **Deployment Fails on IAM Permissions**
   - Ensure GitHub OIDC role has necessary permissions
   - Check AWS CloudTrail for specific permission denials

2. **ECS Tasks Not Starting**
   - Check CloudWatch logs for container errors
   - Verify ECR image exists and is accessible
   - Check security group configurations

3. **Database Connection Issues**
   - Verify RDS instance is running
   - Check security group rules (port 5432)
   - Validate Secrets Manager access

4. **Terraform State Conflicts**
   - State locking prevents most conflicts
   - If locked, wait or manually unlock in DynamoDB
   - Check for concurrent workflow runs

### Manual Recovery

If GitHub Actions fail, you can deploy manually:

```bash
# Deploy base infrastructure
cd infra/base
terraform init
terraform apply

# Build and push image
cd ../../app
$(aws ecr get-login --no-include-email --region us-east-1)
docker build -t cloud-webapp .
docker tag cloud-webapp:latest [ECR_URL]:latest
docker push [ECR_URL]:latest

# Deploy app infrastructure
cd ../infra/app
terraform init
terraform apply
```

## 📈 Cost Management

### Free Tier Resources
- **RDS:** db.t3.micro (750 hours/month)
- **ECS Fargate:** 0.25 vCPU, 0.5GB memory
- **NAT Gateway:** $0.045/hour (not free tier)

### Cost Optimization
- Use cleanup workflow when not testing
- Monitor AWS billing dashboard
- Consider using VPC endpoints to avoid NAT Gateway costs

## 🔐 Security

### Secrets Management
- Database credentials stored in AWS Secrets Manager
- No hardcoded secrets in code or environment variables
- IAM roles use least privilege principles

### Network Security
- RDS in private subnets only
- Security groups restrict access by source
- HTTPS/SSL encryption for data in transit

### Access Control
- GitHub OIDC for AWS access (no long-term keys)
- Terraform state encrypted and locked
- Regular security group and IAM policy reviews

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Free Tier Details](https://aws.amazon.com/free/)
