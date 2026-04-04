variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ami_id" {
  description = "The AMI ID to use"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "db_password" {
  description = "Kiwi TCMS database password"
  type        = string
  sensitive   = true
}
