terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "expensetrack-tfstate-927161113926-eu-west-2-an"
    key            = "expense-tracker/dev.tfstate"
    region         = "eu-west-2"
    use_lockfile = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project    = "expensetrack"
      owner      = "hadya"
      managed_by = "terraform"
    }
  }
}

variable "ami_id" {
  description = "Ubuntu 24.04 AMI (discovered via aws ec2 describe-images)"
  type        = string
  default     = "ami-057b46c043e81dcf4"
}

resource "aws_security_group" "app" {
  name        = "expensetracker-tf-sg"
  description = "Allow SSH from my IP and HTTP from the world"

  ingress {
    description = "SSH from my home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "expensetracker-tf-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "expense-tracker-tf-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name    = "expensetracker-tf-server"
    project = "expensetrack"
    env     = "dev"
  }
}



data "aws_caller_identity" "current" {}

resource "aws_budgets_budget" "monthly" {
  name         = "expense-tracker-monthly"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["hadyatotakhail08@gmail.com"]
  }

  depends_on = [aws_security_group.app]
}
