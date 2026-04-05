resource "aws_s3_bucket" "bia_dev_bucket" {
  bucket = "bia-dev-bucket-terraform"

  tags = merge(var.default
    ,       {
        Name = "BIA-Dev-Bucket"
        }
    )
}

resource "aws_s3_bucket_versioning" "bia_dev_bucket_versioning" {
  bucket = aws_s3_bucket.bia_dev_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


