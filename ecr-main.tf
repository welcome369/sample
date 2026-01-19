provider "aws" {
  region = "ap-south-1"
}

resource "aws_ecr_repository" "aws_ecr" {
  name = "node-images"
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.aws_ecr.name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.aws_ecr.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.aws_ecr.repository_url
}
