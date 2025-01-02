resource "aws_vpc" "medusa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "medusa-vpc"
    Environment = "production"
    Project     = "medusa"
    Terraform   = "true"
  }
}


resource "aws_subnet" "medusa_subnet_1" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "medusa-subnet-1"
  }
}

resource "aws_subnet" "medusa_subnet_2" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "medusa-subnet-2"
  }
}

resource "aws_internet_gateway" "medusa_igw" {
  vpc_id = aws_vpc.medusa_vpc.id

  tags = {
    Name = "medusa-igw"
  }
}

resource "aws_route_table" "medusa_route_table" {
  vpc_id = aws_vpc.medusa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.medusa_igw.id
  }

  tags = {
    Name = "medusa-route-table"
  }
}

resource "aws_route_table_association" "medusa_rta_1" {
  subnet_id      = aws_subnet.medusa_subnet_1.id
  route_table_id = aws_route_table.medusa_route_table.id
}

resource "aws_route_table_association" "medusa_rta_2" {
  subnet_id      = aws_subnet.medusa_subnet_2.id
  route_table_id = aws_route_table.medusa_route_table.id
}

resource "aws_security_group" "medusa_sg" {
  name_prefix  = "medusa-app-sg-"
  description  = "Security group for Medusa application"
  vpc_id       = aws_vpc.medusa_vpc.id

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.medusa_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "medusa-app-sg"
    Environment = "production"
    Project     = "medusa"
    Terraform   = "true"
  }
}