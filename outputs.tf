output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.bia_dev.id
}

output "ec2_instance_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.bia_dev.public_ip
}

output "db_endpoint" {
  description = "Endpoint da instância RDS"
  value       = aws_db_instance.bia.endpoint
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.bia_ecr_repo.repository_url
}

output "db_credentials_secret_name" {
  description = "Nome do segredo do AWS Secrets Manager para a senha do banco de dados"
  value = "${data.aws_secretsmanager_secret.bia_db_credentials.name}"
}