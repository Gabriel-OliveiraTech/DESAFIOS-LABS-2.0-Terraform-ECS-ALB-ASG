resource "aws_ecr_repository" "bia_ecr_repo" {
  name = "bia-ecr-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true
    tags = merge(var.default
        , {
        Name = "BIA-ECR-Repo"
        }
    )

    image_scanning_configuration {
      scan_on_push = false
    }
}