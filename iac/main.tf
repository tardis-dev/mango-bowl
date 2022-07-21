data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = var.task_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 3 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 3
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_name
  requires_compatibilities = ["EC2"]
  network_mode             = "host"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecs-task-execution"

  container_definitions = <<EOF
[
  {
    "name": "${var.task_name}",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.task_name}:${var.image_version}",
    "cpu": 128,
    "memory": 512,
    "essential": true,
    "environment": [
       {
         "name": "MB_ENDPOINT",
         "value": "https://merstab-main-1336.mainnet.rpcpool.com/4e83182e-8757-4a84-81e6-5f0c153bd3a0"
       }
     ],
    "portMapping": [
      {
        "containerPort": 8100,
        "hostPort": 8100,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${var.task_name}",
        "awslogs-stream-prefix": "${var.cluster_name}"
      }
    }
  }
]
EOF
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.task_name
  retention_in_days = 1
}

resource "aws_ecs_service" "this" {
  name            = var.task_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "EC2"

  desired_count = var.desired_count

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
