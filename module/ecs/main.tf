locals {
  vpc_id                    = var.vpc_id
  name                      = trimspace(var.ecs_name)
  ecs_name                  = replace(local.name, " ", "_")
  launch_template_name      = "${local.ecs_name}-template"
  iam_role_name             = "${local.ecs_name}-iam-role"
  iam_policy_name           = "${local.ecs_name}-iam-policy"
  iam_instance_profile_name = "${local.ecs_name}-iam-instance-profile"
  log_group_name            = var.log_group_name
  security_group_name       = "${local.ecs_name}-security-group"
  retention_in_days         = var.retention_in_days
  vpc_subnets_id            = var.vpc_subnets_id
  tags                      = var.ecs_tags
}

data "aws_ami" "message-transmission" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "message-transmission" {
  name        = local.security_group_name
  description = "Allow all traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "Allow all traffic"
  }, local.tags)
}

resource "aws_iam_policy" "message-transmission" {
  name   = local.iam_policy_name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Define the role
resource "aws_iam_role" "message-transmission" {
  name               = local.iam_role_name
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
            "ecs.amazonaws.com"
          ]
        }
      }
    ]
  })
  tags = merge({
    Name = local.name
  }, local.tags)
}

resource "aws_iam_role_policy_attachment" "message-transmission" {
  policy_arn = aws_iam_policy.message-transmission.arn
  role       = aws_iam_role.message-transmission.name
}

resource "aws_iam_role_policy_attachment" "AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.message-transmission.name
}

resource "aws_iam_instance_profile" "message-transmission" {
  name = local.iam_instance_profile_name
  role = aws_iam_role.message-transmission.name
  tags = merge({
    Name = local.name
  }, local.tags)
}

resource "aws_cloudwatch_log_group" "message-transmission" {
  name              = local.log_group_name
  retention_in_days = local.retention_in_days
  tags              = merge(local.tags, {
    "Name" = local.log_group_name
  })
}

resource "aws_ecs_cluster" "message-transmission" {
  name = local.ecs_name
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.message-transmission.name
      }
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.message-transmission
  ]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_autoscaling_group" "message-transmission" {
  name                = local.name
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = local.vpc_subnets_id

  mixed_instances_policy {

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.message-transmission.id
      }
    }
  }

  protect_from_scale_in = true

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
  depends_on = [aws_launch_template.message-transmission]
}

resource "aws_launch_template" "message-transmission" {
  name          = local.launch_template_name
  image_id      = data.aws_ami.message-transmission.image_id
  instance_type = "t3.small"
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
    }
  }
  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [aws_security_group.message-transmission.id]
  lifecycle {
    create_before_destroy = true
  }
  tag_specifications {
    resource_type = "instance"
    tags          = {
      Name = local.name
    }
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.message-transmission.arn
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  tags = merge(local.tags, {
    "Name" = local.name
  })
}

resource "aws_ecs_capacity_provider" "message-transmission" {
  name = local.ecs_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.message-transmission.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      maximum_scaling_step_size = 4
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 2
    }
  }
}

resource "aws_ecs_task_definition" "message-transmission" {
  family                = "service"
  container_definitions = jsonencode([
    {
      name         = "first"
      image        = "service-first"
      cpu          = 1024
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}

resource "aws_ecs_service" "message-transmission" {
  name            = "${local.ecs_name}-service"
  cluster         = aws_ecs_cluster.message-transmission.id
  launch_type     = "EC2"
  desired_count   = 2
  propagate_tags  = "SERVICE"
  task_definition = aws_ecs_task_definition.message-transmission.id
  tags            = merge(local.tags, {
    "Name" = "${local.name}-service"
  })
}
