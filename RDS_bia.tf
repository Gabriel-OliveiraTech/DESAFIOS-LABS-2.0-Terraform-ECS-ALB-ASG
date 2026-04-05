resource "aws_db_instance" "bia" {
  identifier                   = "bia-db-tf"
  allocated_storage            = 10
  username                     = "postgres"
  db_name                      = "bia_db"
  engine                       = "postgres"
  skip_final_snapshot          = true
  multi_az                     = true
  engine_version               = "17.4"
  instance_class               = "db.m5.large"
  manage_master_user_password  = true
  db_subnet_group_name         = aws_db_subnet_group.bia.name
  vpc_security_group_ids       = [aws_security_group.bia_db.id]
  publicly_accessible          = true
  engine_lifecycle_support     = "open-source-rds-extended-support-disabled"
  performance_insights_enabled = false
  monitoring_interval          = 0
  depends_on                   = [aws_internet_gateway.bia_dev_igw]
}

resource "aws_db_subnet_group" "bia" {
  name       = "bia-db-subnet-group"
  subnet_ids = [local.sub_net-1, local.sub_net-2]

  tags = merge(var.default
    , {
      Name = "BIA-DB-Subnet-Group"
    }
  )
}
