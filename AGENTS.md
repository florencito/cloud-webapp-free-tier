# AGENTS

This project is a cloud-native web application deployment using the AWS Free Tier.

## Technologies in Use

- FastAPI (Python backend)
- Docker
- AWS ECS (Fargate)
- AWS ECR
- AWS RDS (PostgreSQL or MySQL)
- Terraform (IaC)
- GitHub Actions (CI/CD)
- GitHub Secrets (or OIDC) for secure deployments

## Architecture Overview

The app is containerized and deployed using ECS with Fargate. The database is hosted in RDS. Docker images are stored in ECR. All infrastructure is defined via Terraform modules and deployed via GitHub Actions workflows.

## Notes for Codex

- All Terraform files are in `/infra/`
- Backend application is in `/app/`
- CI/CD workflows are in `.github/workflows/`
- Dockerfile is in `/app/Dockerfile`

Generate code accordingly with this structure in mind.
