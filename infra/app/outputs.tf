output "ecs_service_name" {
  value = aws_ecs_service.web.name
}

output "task_definition" {
  value = aws_ecs_task_definition.web.arn
}
