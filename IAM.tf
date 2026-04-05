resource "aws_iam_instance_profile" "bia_dev" {
  name = "bia-dev-instance-profile"
  role = aws_iam_role.bia_dev_role.name

  tags = merge(var.default
    , {
      Name = "BIA-Dev-Instance-Profile"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role       = aws_iam_role.bia_dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bia_dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.bia_dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}



resource "aws_iam_role" "bia_dev_role" {
  name = "bia-dev-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.default
    , {
      Name = "BIA-Dev-Role"
    }
  )
}
