terraform {
  backend "s3" {
    bucket         = "cloud-webapp-free-tier-terraform-state-e652a150fd6fe784"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-webapp-free-tier-terraform-locks"
    encrypt        = true
  }
}
