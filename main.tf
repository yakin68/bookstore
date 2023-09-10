terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region  = "us-east-1"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

variable "secgr-dynamic-ports" {
  default = [22,80,443,3306]
}

variable "instance-type" {
  default = "t2.micro"
  sensitive = true
}

resource "aws_security_group" "allow_ssh2" {
  name        = "allow_ssh2"
  description = "Allow SSH inbound traffic"

  dynamic "ingress" {
    for_each = var.secgr-dynamic-ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tf-ec2" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance-type
  key_name = "end-key-pair"
  vpc_security_group_ids = [ aws_security_group.allow_ssh2.id ]
  user_data = filebase64("user-data.sh")
      tags = {
      Name = "Web Server of Bookstore"
  }
}  
output "myec2-public-ip" {
  value = aws_instance.tf-ec2.public_ip
}
output "ssh-connection-command" {
  value = "ssh -i ${aws_instance.tf-ec2.key_name}.pem ec2-user@${aws_instance.tf-ec2.public_ip}"
}