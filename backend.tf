terraform {
  backend "s3" {
    bucket         = "econstruction-terraform-state"
    key            = "state"
    region         = "us-east-1"
    encrypt        = true
  }
}
