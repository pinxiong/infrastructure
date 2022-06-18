############################################################################################
##==============================Define security group=====================================##
############################################################################################
resource "aws_security_group" "elb" {
  name        = "${local.project_name}-elb"
  description = "Allow all traffic to visit ${local.project_name}"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic to visit ${local.project_name}"
  }

  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = merge({
    Name : "${local.project_name}-elb"
  }, local.tags)
}

resource "aws_security_group" "ecs_service" {
  name        = local.ecs_service_name
  description = "Allow ${local.project_name}-elb to visit"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "TCP"
    security_groups = [aws_security_group.elb.id]
    description     = "Allow ${local.project_name}-elb to visit"
  }

  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = merge({
    Name : local.ecs_service_name
  }, local.tags)
}

############################################################################################
##=============================Define elb related resources===============================##
############################################################################################
resource "aws_lb" "ecs_service" {
  name               = "${local.project_name}-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb.id]
  subnets            = flatten([local.vpc_public_subnets_id])
  tags               = merge({
    Name = local.project_name
  }, local.tags)
}

resource "aws_lb_target_group" "ecs_service" {
  name        = "${local.project_name}-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 300
    path                = "/health"
    timeout             = 60
    matcher             = "200"
    port                = 8080
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }
  tags = merge({
    Name = local.project_name
  }, local.tags)
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_service.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_service.arn
  }
}

############################################################################################
##==============================Define IAM role and policy================================##
############################################################################################
resource "aws_iam_policy" "ecs" {
  name   = "${local.ecs_cluster_name}-policy"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "*",
      }
    ]
  })
}

resource "aws_iam_role" "ecs" {
  name               = lower("${local.ecs_cluster_name}-role")
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "ec2.amazonaws.com",
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "application-autoscaling.amazonaws.com"
          ]
        }
      }
    ]
  })
  tags = merge({
    Name : local.ecs_cluster_name
  }, local.tags)
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  policy_arn = aws_iam_policy.ecs.arn
  role       = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy__AmazonECS_FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy__ElasticLoadBalancingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy__CloudWatchFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy__AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy__AmazonEC2ContainerServiceforEC2Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy__AmazonEC2ContainerServiceAutoscaleRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  role       = aws_iam_role.ecs.name
}

############################################################################################
##=============================Define ecs related resources===============================##
############################################################################################
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/"
  retention_in_days = 1
  tags              = merge(local.tags, {
    Name = local.ecs_cluster_name
  })
}

resource "aws_ecs_cluster" "ecs" {
  name = local.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }
  tags = merge(local.tags, {
    Name = local.ecs_cluster_name
  })
}

resource "aws_ecs_service" "ecs" {
  name                               = local.ecs_service_name
  cluster                            = aws_ecs_cluster.ecs.id
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  network_configuration {
    subnets          = flatten(local.vpc_private_subnets_id)
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }
  task_definition = aws_ecs_task_definition.ecs.arn
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_service.arn
    container_name   = local.container_name
    container_port   = 8080
  }
  health_check_grace_period_seconds = local.health_check_grace_period_seconds
  tags                              = merge(local.tags, {
    Name = local.ecs_service_name
  })
}

resource "aws_ecs_task_definition" "ecs" {
  family                   = "${local.project_name}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${local.cpu}"
  memory                   = "${local.memory}"
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "${local.container_name}",
      "image": "${local.image}",
      "cpu": ${local.cpu},
      "memory": ${local.memory},
      "essential": true,
      "workingDirectory":"/go/src/project/",
      "portMappings": [
        {
          "hostPort": 8080,
          "protocol": "tcp",
          "containerPort": 8080
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.ecs.name}",
          "awslogs-region": "${local.region}",
          "awslogs-create-group": "true",
          "awslogs-stream-prefix": "${local.project_name}"
        }
      }
    }
  ]
  TASK_DEFINITION
  task_role_arn            = aws_iam_role.ecs.arn
  execution_role_arn       = aws_iam_role.ecs.arn
}

############################################################################################
##=============================Define auto scaling for ecs================================##
############################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_out_alarm" {
  alarm_name          = "Alarm-scal-out-for-${local.ecs_cluster_name}-${local.ecs_service_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    ClusterName = local.ecs_cluster_name
    ServiceName = local.ecs_service_name
  }

  alarm_description = "This metric monitor ecs CPU utilization up."
  alarm_actions     = [aws_appautoscaling_policy.ecs_scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_in_alarm" {
  alarm_name          = "Alarm-scale-in-for-${local.ecs_cluster_name}-${local.ecs_service_name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    ClusterName = local.ecs_cluster_name
    ServiceName = local.ecs_service_name
  }

  alarm_description = "This metric monitor ecs CPU utilization down."
  alarm_actions     = [aws_appautoscaling_policy.ecs_scale_in.arn]
}

resource "aws_appautoscaling_target" "ecs" {
  min_capacity       = local.min_capacity
  max_capacity       = local.max_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.ecs.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scale_out" {
  name               = "${local.ecs_service_name}-scale-out-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    // scale-out policy
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 2
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_scale_in" {
  name               = "${local.ecs_service_name}-scale-in-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    //scale-in policy
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}