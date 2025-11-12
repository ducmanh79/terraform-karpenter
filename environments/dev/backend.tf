# Backend configuration for remote state management
# Uncomment and configure after creating the S3 bucket and DynamoDB table

# terraform {
#   backend "s3" {
#     bucket         = "devops-takehome-terraform-state-bucket"
#     key            = "eks/dev/terraform.tfstate"
#     region         = "ap-southeast-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#
#     # role_arn = "arn:aws:iam::975049985236:role/TerraformStateRole"
#   }
# }

# To set up remote state:
# 1. Create an S3 bucket for state storage
# 2. Create a DynamoDB table for state locking
# 3. Uncomment and configure the backend block above
# 4. Run: terraform init -migrate-state
