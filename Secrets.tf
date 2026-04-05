data "aws_secretsmanager_secret" "bia_db_credentials" {
  arn = aws_db_instance.bia.master_user_secret[0].secret_arn
}