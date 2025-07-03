terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Networking
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  tags = {
    Name = "SecureApp-VPC"
  }
}

resource "aws_subnet" "public_az_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

# 2. Compute
resource "aws_lb" "app_alb" {
  name               = "secureapp-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_az_a.id, aws_subnet.public_az_b.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

# 3. Security
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTPS inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Database
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.private.name
  storage_encrypted    = true
  skip_final_snapshot  = true
}

output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}