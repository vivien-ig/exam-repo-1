
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "availability_zone" {
  description = "Availability Zone for the subnets"
  type        = string
  default     = "ca-central-1a"
}

variable "ami_id" {
  description = "Valid Amazon Linux 2023 AMI ID in the selected region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Public IP CIDR permitted to connect over SSH"
  type        = string
  default     = "0.0.0.0/0"
}
