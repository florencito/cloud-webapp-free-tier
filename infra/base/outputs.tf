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

output "rds_endpoint" {
  value = aws_db_instance.webapp.address
}

output "rds_db_name" {
  value = aws_db_instance.webapp.db_name
}

output "rds_user" {
  value = aws_db_instance.webapp.username
}

output "rds_password" {
  value = aws_db_instance.webapp.password
}
