

resource "aws_vpc" "exam_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "exam-vpc"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.exam_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "exam-public-subnet"
  }
}


resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.exam_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "exam-private-subnet"
  }
}


resource "aws_internet_gateway" "exam_igw" {
  vpc_id = aws_vpc.exam_vpc.id

  tags = {
    Name = "exam-igw"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.exam_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.exam_igw.id
  }

  tags = {
    Name = "exam-public-route-table"
  }
}


resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_security_group" "exam_sg" {
  name        = "exam-security-group"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.exam_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "exam-security-group"
  }
}


resource "aws_instance" "exam_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.exam_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  tags = {
    Name = "exam-public-instance"
  }
}


resource "aws_kms_key" "s3_kms" {
  description             = "S3-KMS"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name = "S3-KMS"
  }
}


resource "aws_kms_alias" "s3_kms_alias" {
  name          = "alias/S3-KMS"
  target_key_id = aws_kms_key.s3_kms.key_id
}


resource "random_id" "bucket_suffix" {
  byte_length = 4
}


resource "aws_s3_bucket" "logs_bucket" {
  bucket = "exam-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "exam-logs-bucket"
  }
}


resource "aws_s3_bucket_public_access_block" "logs_bucket_access" {
  bucket = aws_s3_bucket.logs_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Encrypt S3 objects using the KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }

    bucket_key_enabled = true
  }
}

# DynamoDB table
resource "aws_dynamodb_table" "sessions" {
  name         = "exam-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionId"

  attribute {
    name = "SessionId"
    type = "S"
  }

  tags = {
    Name = "exam-sessions"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.exam_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "ec2_instance_id" {
  value = aws_instance.exam_ec2.id
}

output "ec2_public_ip" {
  value = aws_instance.exam_ec2.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.logs_bucket.bucket
}

output "kms_key_arn" {
  value = aws_kms_key.s3_kms.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.sessions.name
}
