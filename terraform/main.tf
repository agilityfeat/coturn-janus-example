provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_vpc" "main" {
  id = var.main_vpc
}

data "aws_subnet" "main_public" {
  id = var.main_public_subnet
}

resource "aws_instance" "janus_dev" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.main_public.id
  key_name               = var.main_ssh_keyname
  vpc_security_group_ids = [aws_security_group.janus_dev.id]

  tags = {
    app  = "janus"
    env  = "dev"
    Name = "janus-dev"
  }
}

resource "aws_instance" "coturn_dev" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.main_public.id
  key_name               = var.main_ssh_keyname
  vpc_security_group_ids = [aws_security_group.coturn_dev.id]

  tags = {
    app  = "coturn"
    env  = "dev"
    Name = "coturn-dev"
  }
}

resource "aws_eip" "janus-dev" {
  instance = aws_instance.janus_dev.id
  vpc      = true
}

resource "aws_eip" "coturn-dev" {
  instance = aws_instance.coturn_dev.id
  vpc      = true
}

resource "aws_security_group" "coturn_dev" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env  = "dev"
    app  = "coturn"
    Name = "coturn-dev-security-group"
  }
}

resource "aws_security_group" "janus_dev" {
  ingress {
    from_port   = 8188
    to_port     = 8188
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7088
    to_port     = 7088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5004
    to_port     = 5004
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env  = "dev"
    app  = "janus"
    Name = "janus-dev-security-group"
  }
}
