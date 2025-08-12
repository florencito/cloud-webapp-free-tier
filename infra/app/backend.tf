terraform {
  backend "s3" {
    bucket         = "cloud-webapp-free-tier-terraform-state-254eff5ef13ce623"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-webapp-free-tier-terraform-locks"
    encrypt        = true
  }
}
