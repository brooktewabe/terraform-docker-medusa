# Define the AWS region variable
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-3" # optional, default value if not provided in terraform.tfvars
}

# Define the domain name variable
variable "domain_name" {
  description = "The domain name to be used"
  type        = string
}
variable "subdomain" {
  description = "The subdomain for the Medusa application"
  type        = string
}
variable "certificate_domain" {
  description = "The domain name of the existing ACM certificate"
  type        = string
}
variable "neon_db_url" {
  description = "The connection URL for Neon DB"
  type        = string
}
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "medusa"
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}