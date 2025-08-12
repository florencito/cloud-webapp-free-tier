provider "aws" {
  region = var.aws_region
}

# Leer los outputs del módulo base
data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "cloud-webapp-free-tier-terraform-state-254eff5ef13ce623"
    key    = "base/terraform.tfstate"
    region = "us-east-1"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "cloud-webapp-cluster"
}

# IAM Role para ejecución de ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM policy to allow access to Secrets Manager and CloudWatch Logs
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.terraform_remote_state.base.outputs.rds_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Task Definition
resource "aws_ecs_task_definition" "web" {
  family                   = "cloud-webapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "cloud-webapp"
      image     = "${data.terraform_remote_state.base.outputs.ecr_repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      secrets = [
        {
          name      = "DB_CREDENTIALS"
          valueFrom = data.terraform_remote_state.base.outputs.rds_secret_arn
        }
      ]

      portMappings = [
        {
          containerPort = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/cloud-webapp-task"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

# Service ECS
resource "aws_ecs_service" "web" {
  name            = "cloud-webapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.terraform_remote_state.base.outputs.public_subnet_id]
    security_groups  = [data.terraform_remote_state.base.outputs.security_group_id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_attach
  ]
}
