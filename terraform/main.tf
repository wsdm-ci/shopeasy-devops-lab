# ---------------------------------------------------------------
# main.tf - the resources we want Terraform to create
# ---------------------------------------------------------------

# Tell Terraform which cloud (AWS) and which version of the AWS plugin to use
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider (the region comes from variables.tf)
provider "aws" {
  region = var.region
}

# 1. VPC - your own private network inside AWS
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Internet Gateway - the "door" that connects the VPC to the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 3. Subnet - a smaller section of the VPC where the EC2 instance lives
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.region}a"
  # availability_zone = var.availability_zone


  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# 4. Route table - tells the subnet to send internet traffic (0.0.0.0/0)
#    through the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Attach the route table to the subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 5. Security group - the firewall for the EC2 instance
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP (port 80) from the internet"
  vpc_id      = aws_vpc.main.id

  # Inbound rule: allow port 80 (HTTP) from anywhere on the internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule: allow port 22 (SSH) so you can log in to the server
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule: allow the instance to reach anything
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# 6. EC2 instance - the virtual server
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # user_data is a script that runs ONCE, the first time the server boots.
  # Here it creates a user with sudo (superuser) rights and enables password login.
  # ${var.vm_username} and ${var.vm_password} are filled in by Terraform.
  user_data = <<-EOF
    #!/bin/bash
    # Create the user and give them a home folder
    useradd -m -s /bin/bash ${var.vm_username}
    # Set the password
    echo "${var.vm_username}:${var.vm_password}" | chpasswd
    # Add the user to the sudo group (superuser rights)
    usermod -aG sudo ${var.vm_username}
    # Ubuntu blocks SSH password login by default - turn it on.
    # The file name starts with 01 so it is read before Ubuntu's own settings.
    echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/01-password-auth.conf
    systemctl restart ssh
  EOF

  # If you change the script, recreate the instance so it runs again
  user_data_replace_on_change = true

  tags = {
    Name     = "${var.project_name}-ec2"
    Training = "ShopEasy-DevOps-Lab"
  }
}

# 7. Elastic IP - a fixed public IP address that doesn't change on restart
resource "aws_eip" "web" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }

  # Make sure the internet gateway exists before creating the EIP
  depends_on = [aws_internet_gateway.igw]
}

# Attach the Elastic IP to the EC2 instance
resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}
