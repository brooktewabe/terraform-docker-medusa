<p align="center">
  <a href="https://www.medusajs.com">
    <img alt="Medusa" src="https://user-images.githubusercontent.com/7554214/153162406-bf8fd16f-aa98-4604-b87b-e13ab4baf604.png" width="100" />
  </a>
</p>

# Medusa Backend AWS Infrastructure setup

This repository contains the infrastructure as code (IaC) setup using Terraform and Docker for deploying Medusa e-commerce platform on AWS.

## Architecture Overview

The infrastructure setup includes:
- ECS for container orchestration
- AWS Fargate for serverless compute engine 
- Application Load Balancer (ALB) for traffic distribution
- ElastiCache Redis for caching
- Neon Database (external) for PostgreSQL
- Route53 for DNS management
- ACM for SSL/TLS certificates
- ECR for container registry
- VPC with public subnets across multiple AZs

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker
- Domain name with Route53 hosted zone and certificate
- Database account and connection string eg. Neon DB

## Quick Start

1. Clone this repository:
```bash
git clone <repository-url>
cd medusa-infrastructure
```

2. Update `terraform.tfvars` with your values:
```hcl
aws_region         = "your-region"
domain_name        = "your-domain.com"
subdomain          = "manage"
neon_db_url        = "your-neon-db-url"
certificate_domain = "*.your-domain.com"
```

3. Initialize Terraform:
```bash
terraform init
```

4. Deploy the infrastructure:
```bash
terraform plan
terraform apply
```

5. Build and push Docker image:
```bash
# Login to ECR
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.<region>.amazonaws.com

# Build image
docker build -t medusa-repo .

# Tag image
docker tag medusa-repo:latest <aws-account-id>.dkr.ecr.<region>.amazonaws.com/medusa-repo:latest

# Create repo
aws ecr create-repository --repository-name your-repo-name

```
# Push image
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/medusa-repo:latest

## Infrastructure Components
```

### Networking
- VPC with CIDR block 10.0.0.0/16
- Two public subnets across different AZs
- Internet Gateway for public internet access
- Route tables for subnet routing

### Security
- Security groups for ALB, ECS tasks, and Redis
- IAM roles and policies for ECS tasks
- SSL/TLS certificate management

### Container Infrastructure
- ECS Cluster with Fargate launch type
- Auto-scaling policies based on CPU and memory utilization
- ECR repository with lifecycle policies

### Load Balancing
- Application Load Balancer
- HTTPS listener with SSL certificate
- HTTP to HTTPS redirect
- Health checks configuration

### Caching
- Redis ElastiCache cluster
- Subnet group for Redis deployment
- Security group for Redis access

## Environment Variables

The following environment variables are configured in the ECS task definition:
- `REDIS_URL`: Auto-generated from ElastiCache, use this in .env file
- `NODE_ENV`: Set to "production"
- `DATABASE_URL`: Provided via terraform.tfvars

## Monitoring and Logging

- CloudWatch Log Groups for container logs
- Container Insights enabled on ECS cluster
- ALB access logs (optional)

## Security Considerations

- All resources are deployed within a VPC
- Security groups limit access to required ports only
- HTTPS enforced with HTTP to HTTPS redirect
- IAM roles follow principle of least privilege
- Redis access restricted to ECS tasks

## Cost Optimization

- Fargate Spot can be used for cost savings
- Auto-scaling based on demand
- ECR lifecycle policies to manage image storage
- ElastiCache instance sized appropriately

## Maintenance

### Updating the Application
1. Build new Docker image
2. Push to ECR
3. Update ECS service (automatic with latest tag)

### Infrastructure Updates
1. Update Terraform code
2. Run `terraform plan` to review changes
3. Apply changes with `terraform apply`

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
