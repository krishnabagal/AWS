terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# -------------------------
# Data Sources
# -------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "computehub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "ComputeHub-VPC"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.computehub.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "ComputeHub-PublicSubnet"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.computehub.id

  tags = {
    Name        = "ComputeHub-IGW"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.computehub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "ComputeHub-PublicRT"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Group
# -------------------------

resource "aws_security_group" "computehub" {
  name        = "ComputeHubSG"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.computehub.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ComputeHubSG"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

# -------------------------
# IAM
# -------------------------

resource "aws_iam_role" "computehub" {
  name = "ComputeHubEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "ComputeHubEC2Role"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.computehub.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "computehub" {
  name = "ComputeHubInstanceProfile"
  role = aws_iam_role.computehub.name
}

# -------------------------
# S3
# -------------------------

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "computehub-artifacts-"

  tags = {
    Name        = "ComputeHub-Artifacts"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

# -------------------------
# EC2 User Data
# -------------------------

locals {
  user_data = <<-EOF
    #!/bin/bash

    exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    dnf install -y awscli

    echo "ComputeHub startup script started"

    aws s3 ls s3://${aws_s3_bucket.artifacts.bucket}

    echo "ComputeHub startup script completed"
  EOF
}

# -------------------------
# EC2
# -------------------------

resource "aws_instance" "computehub" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.computehub.id]
  key_name                    = "ComputeHubKey"
  iam_instance_profile        = aws_iam_instance_profile.computehub.name
  associate_public_ip_address = true

  user_data = local.user_data

  tags = {
    Name        = "ComputeHub-DevServer"
    Project     = "ComputeHub"
    Environment = "Development"
  }
}

# -------------------------
# Outputs
# -------------------------

output "vpc_id" {
  value = aws_vpc.computehub.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "instance_id" {
  value = aws_instance.computehub.id
}

output "instance_public_ip" {
  value = aws_instance.computehub.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}
