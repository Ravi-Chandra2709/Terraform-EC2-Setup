terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.36"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region  = "us-east-1"          # Change to your preferred AWS region
  profile = "default"            # Ensure AWS CLI profile is correctly set
}

# Create an EC2 Security Group
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"

  # Allow SSH inbound from any IP (change for security)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to specific IP for better security
  }

  # Allow HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate an SSH Key Pair (stored locally)
resource "tls_private_key" "tf_ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "tf_ec2_key" {
  content  = tls_private_key.tf_ec2_key.private_key_pem
  filename = "${path.module}/tf_ec2_key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "tf_ec2_key" {
  key_name   = "tf_ec2_key"
  public_key = tls_private_key.tf_ec2_key.public_key_openssh
}

# Launch EC2 Instance (Free Tier Eligible)
resource "aws_instance" "example" {
  ami                    = "ami-<id>"  # Ubuntu Server 22.04 LTS # replace this with ami id you want to 
  instance_type          = "t2.micro"  # Free-tier eligible instance
  key_name               = aws_key_pair.tf_ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tags = {
    Name = "MyFreeTierEC2"
  }
}

# Output the Public IP of the EC2 instance
output "ec2_public_ip" {
  value = aws_instance.example.public_ip
}
