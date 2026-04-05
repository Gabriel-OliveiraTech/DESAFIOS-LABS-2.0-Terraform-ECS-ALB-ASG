terraform {
  backend "s3" {
    bucket       = "bia-dev-bucket-terraform"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    profile      = "SEU PERFIL AWS AQUI"
  }
}