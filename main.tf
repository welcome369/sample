provider "aws" {
  region = "ap-south-1" # Change to your preferred region
}

resource "aws_s3_bucket" "terraform_bucket" {
  bucket = "my-terraform-state-bucket3695799"  # Change to a unique name
}
