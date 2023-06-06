provider "aws" {
  region = "us-east-1"
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
    to_port     = 3479
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3478
    to_port     = 3479
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5349
    to_port     = 5350
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5349
    to_port     = 5350
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5766
    to_port     = 5766
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 49152
    to_port     = 65535
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
    to_port     = 7089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8088
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8889
    to_port     = 8889
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10000
    to_port     = 10100
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

resource "aws_s3_bucket" "main_app" {
  bucket = "hector-networking-basics-demo"

  tags = {
    Name = "Client App - WebRTC Networking Demo"
  }
}

resource "aws_cloudfront_origin_access_identity" "client_app_origin_access_identity" {
  comment = "Origin access identity for accesing to app bucket"
}

data "aws_iam_policy_document" "client_app_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main_app.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.client_app_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "main_policy" {
  bucket = aws_s3_bucket.main_app.id
  policy = data.aws_iam_policy_document.client_app_s3_policy.json
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "The cloudfront distribution for client app"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.main_app.bucket_regional_domain_name
    origin_id   = "app_origin_id"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.client_app_origin_access_identity.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_instance.janus_dev.public_dns
    origin_id   = "janus_origin_id"

    custom_origin_config {
      http_port              = 8188
      https_port             = 8188
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "app_origin_id"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/janus"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "janus_origin_id"
    
    forwarded_values {
      query_string = true
      headers = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern           = "/janus/*"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "janus_origin_id"
    
    forwarded_values {
      query_string = true
      headers = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  tags = {
    Name        = "CloudFrount Distribution - WebRTC Networking Demo"
  }
}

output "AppUrl" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "JanusServerIp" {
  value = aws_eip.janus-dev.public_ip
}

output "CoturnServerIp" {
  value = aws_eip.coturn-dev.public_ip
}

output "S3BucketName" {
  value = aws_s3_bucket.main_app.id
}