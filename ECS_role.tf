#-------- Create a custom policy to allow ECS tasks to retrieve secrets from Secrets Manager-------------------

resource "aws_iam_role" "bia_ecs_task_execution_role" {
  name               = "bia-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.bia_ecs_task_execution_role_policy.json
}


data "aws_iam_policy_document" "bia_ecs_task_execution_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

}


resource "aws_iam_policy" "get_secret_value_policy" {
  name        = "get-secret-value-policy"
  description = "Policy to allow ECS tasks to retrieve secrets from Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "${aws_db_instance.bia.master_user_secret[0].secret_arn}"
      }
    ]
  })

}


resource "aws_iam_role_policy_attachment" "attach_get_secret_value_policy" {
  role       = aws_iam_role.bia_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.get_secret_value_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.bia_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
