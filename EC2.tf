resource "aws_instance" "bia_dev" {
  ami                    = "ami-02dfbd4ff395f2a1b" # Amazon Linux 2023 kernel-6.1 AMI
  instance_type          = "t3a.micro"             # Recommended for development and testing
  vpc_security_group_ids = [aws_default_security_group.default.id]
  subnet_id              = aws_subnet.sub_1.id
  iam_instance_profile   = aws_iam_instance_profile.bia_dev.name
  user_data              = file("user_data.sh")
  
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(var.default
    , {
      Name = "BIA-Dev-terraform"
    }
  )

}


#---------------------------security group-----------------------------------------------

resource "aws_security_group" "bia_dev" {
  name        = "bia-dev"
  description = "Security group for BIA development environment"

  vpc_id = local.vpc_bia

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default
    , {
      Name = "BIA-Dev-Security-Group"
    }
  )

}


resource "aws_security_group" "bia_web" {
  name        = "bia-web"
  description = "Security group for BIA web environment"

  vpc_id = local.vpc_bia

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default
    , {
      Name = "BIA-Web-Security-Group"
    }
  )

}

resource "aws_security_group" "bia_db" {
  name        = "bia-db"
  description = "Security group for BIA database environment"

  vpc_id = local.vpc_bia

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.bia_dev.id, aws_security_group.bia_ec2.id, aws_security_group.bia_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default
    , {
      Name = "BIA-DB-Security-Group"
    }
  )

}


resource "aws_security_group" "bia_alb" {
  name        = "bia-alb"
  description = "Security group for BIA application load balancer"

  vpc_id = local.vpc_bia

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = merge(var.default
    , {
      Name = "BIA-ALB-Security-Group"
    }
  )

}


resource "aws_security_group" "bia_ec2" {
  name        = "bia-ec2"
  description = "Security group for BIA EC2 instances"

  vpc_id = local.vpc_bia

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.bia_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default
    , {
      Name = "BIA-EC2-Security-Group"
    }
  )

}




