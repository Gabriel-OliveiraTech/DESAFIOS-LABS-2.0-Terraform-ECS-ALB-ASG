# VPC for BIA Dev environment

resource "aws_vpc" "bia_dev_vpc" {
  cidr_block           = "172.50.16.0/27"
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = merge(var.default
    , {
      Name = "BIA-Dev-VPC"
    }
  )
}

resource "aws_subnet" "sub_1" {
  vpc_id                  = local.vpc_bia
  cidr_block              = "172.50.16.0/28"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = merge(var.default
    , {
      Name = "subnet-1"
    }
  )
}


resource "aws_subnet" "sub_2" {
  vpc_id            = local.vpc_bia
  cidr_block        = "172.50.16.16/28"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  

  tags = merge(var.default
    , {
      Name = "subnet-2"
    }
  )
}


# Security Group for BIA Dev environment

resource "aws_default_security_group" "default" {
  vpc_id = local.vpc_bia


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "bia_dev_igw" {
  vpc_id = local.vpc_bia

  tags = merge(var.default
    , {
      Name = "BIA-Dev-IGW"
    }
  )
}


resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.bia_dev_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bia_dev_igw.id
  }
}

resource "aws_route_table_association" "subnet_1" {
  subnet_id      = aws_subnet.sub_1.id
  route_table_id = aws_vpc.bia_dev_vpc.default_route_table_id
}

