# ---------------------------------------------------------------
# outputs.tf - values Terraform prints after `terraform apply`
# ---------------------------------------------------------------

output "security_group_id" {
  description = "ID of the security group attached to the EC2 instance"
  value       = aws_security_group.web.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.web.name
}

# Bonus: handy to see which IP your server is reachable on
output "elastic_ip" {
  description = "Public Elastic IP of the EC2 instance"
  value       = aws_eip.web.public_ip
}
