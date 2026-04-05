#----------------------ECS Cluster and capacity provider association-----------------

resource "aws_ecs_cluster" "bia_ecs_cluster" {
  name = "bia-ecs-cluster"

}


resource "aws_ecs_cluster_capacity_providers" "bia_cluster_cp" {
  cluster_name = aws_ecs_cluster.bia_ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.bia_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.bia_capacity_provider.name
    weight            = 100
    base              = 1
  }
}


resource "aws_ecs_service" "bia_ecs_service" {
  name            = "bia-service"
  cluster         = aws_ecs_cluster.bia_ecs_cluster.id
  task_definition = aws_ecs_task_definition.bia_task_definition.arn
  desired_count   = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100
  depends_on = [aws_lb_target_group.bia_target_group] 



    lifecycle {
    ignore_changes = [ desired_count ]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.bia_capacity_provider.name
    weight            = 100
    base              = 1
  }

  ordered_placement_strategy {
    type = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bia_target_group.arn
    container_name   = "bia-container"
    container_port   = 8080    
  }


}

#-----------------------ECS Task Definition-----------------------------------


resource "aws_ecs_task_definition" "bia_task_definition" {
  family        = "bia-task-family"
  network_mode  = "bridge"
  execution_role_arn = aws_iam_role.bia_ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.bia_ecs_task_execution_role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }


  container_definitions = jsonencode([
    {
      name              = "bia-container"
      image             = "${aws_ecr_repository.bia_ecr_repo.repository_url}:latest"
      essential         = true
      cpu               = 1024
      memoryReservation = 400
      environment = [
        {
          name  = "DB_HOST"
          value = "${aws_db_instance.bia.address}"
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_SECRET_NAME"
          value = "${data.aws_secretsmanager_secret.bia_db_credentials.name}"
        },
        {
          name  = "DB_REGION"
          value = "us-east-1"
        },
        {
          name  = "DEBUG_SECRET"
          value = "true"
        }
      ]

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 0
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bia_log_group.name,
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "bia"
        }

      },
  }])

}




#------------capacity provider, launch template and autoscaling group for ECS cluster-----------------

resource "aws_ecs_capacity_provider" "bia_capacity_provider" {
  name = "bia-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.bia_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }

  tags = merge(var.default
    , {
      Name = "BIA-Capacity-Provider"
    }
  )

}



resource "aws_autoscaling_group" "bia_asg" {
  name                = "bia-asg"
  max_size            = 2
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [local.sub_net-1, local.sub_net-2]

  
  lifecycle {
    ignore_changes = [ desired_capacity ] # Ignore changes to desired_capacity to prevent Terraform from trying to reset it to 1
  }

  launch_template {
    id      = aws_launch_template.bia_lt.id
    version = "$Latest"
  }


  tag {
    key                 = "Name"
    value               = "BIA-Dev-ASG"
    propagate_at_launch = true
  }


  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

data "aws_ssm_parameter" "ecs_ami_recommended" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "bia_lt" {
  name_prefix   = "bia-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami_recommended.value
  instance_type = "t3.micro"
  iam_instance_profile { arn = aws_iam_instance_profile.bia_dev.arn }
  monitoring { enabled = true }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.bia_ecs_cluster.name} >> /etc/ecs/ecs.config;
    EOF    
  )
  network_interfaces {
    security_groups             = [aws_security_group.bia_ec2.id]
    associate_public_ip_address = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 35
      volume_type = "gp3"
    }
  }

  tags = merge(var.default
    , {
      Name = "BIA-Dev-Launch-Template"
    }
  )
}
