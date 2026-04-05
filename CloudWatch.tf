resource "aws_cloudwatch_log_group" "bia_log_group" {
  name = "/aws/ecs/bia"
  retention_in_days = 7
}
