output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.webapp.repository_url
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
  description = "ARN of the RDS credentials secret in AWS Secrets Manager"
}
