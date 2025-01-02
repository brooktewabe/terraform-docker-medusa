resource "aws_ecs_cluster" "medusa_cluster" {
  name = "medusa-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
    tags = {
    Name        = "medusa-cluster"
    Environment = "production"
    Project     = "medusa"
    Terraform   = "true"
  }
}

resource "aws_ecs_task_definition" "medusa_task" {
  family                   = "medusa-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "medusa-container"
      image     = "${aws_ecr_repository.medusa_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.medusa_redis.cache_nodes.0.address}:${aws_elasticache_cluster.medusa_redis.port}"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        },
          {
          name  = "DATABASE_URL"
          value = var.neon_db_url
        }
      ]
      # secrets = [
      #   {
      #     name      = "REDIS_URL"
      #     valueFrom = aws_ssm_parameter.redis_url.arn
      #   }
      # ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.medusa_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "medusa_service" {
  name            = "medusa-service"
  cluster         = aws_ecs_cluster.medusa_cluster.id
  task_definition = aws_ecs_task_definition.medusa_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 100
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = [aws_subnet.medusa_subnet_1.id, aws_subnet.medusa_subnet_2.id]
    security_groups  = [aws_security_group.medusa_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.medusa_tg.arn
    container_name   = "medusa-container"
    container_port   = 9000
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent        = 200

  health_check_grace_period_seconds = 60

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_cloudwatch_log_group" "medusa_logs" {
  name              = "/ecs/medusa-logs"
  retention_in_days = 30
}

resource "aws_appautoscaling_target" "medusa_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.medusa_cluster.name}/${aws_ecs_service.medusa_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "medusa_cpu" {
  name               = "medusa-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.medusa_target.resource_id
  scalable_dimension = aws_appautoscaling_target.medusa_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.medusa_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "medusa_memory" {
  name               = "medusa-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.medusa_target.resource_id
  scalable_dimension = aws_appautoscaling_target.medusa_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.medusa_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}