# ---------------------------------------------------------------
# variables.tf - values you can change without touching main.tf
# ---------------------------------------------------------------

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "availability_zone" {
  description = "Availability zone for the subnet (must be inside the region above)"
  type        = string
  default     = "us-east-2a"
}

variable "project_name" {
  description = "Prefix used to name all resources"
  type        = string
  default     = "chukwuebuka-igboabuchukwu-terraform-shopeasy-lab"
}

variable "vpc_cidr" {
  description = "IP range for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "IP range for the subnet (must fit inside the VPC range)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Size of the EC2 instance"
  type        = string
  default     = "t3.micro"
}

# named TF_VAR_vm_username and TF_VAR_vm_password (see instructions)
variable "vm_username" {
  description = "Username to create on the server"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "Password for that user"
  type        = string
  default     = "changeME"
  sensitive   = true # hides the value in Terraform's screen output
}

variable "ami_id" {
  description = "AMI (operating system image) for the EC2 instance. AMI IDs differ per region - the default is Amazon Linux 2023 in us-east-1; look up a current one in the EC2 console if it fails."
  type        = string
  default     = "ami-0fa99aa8f97f9e30b"
}
