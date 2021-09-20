output "clair_rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.clair_db.address
  sensitive   = false
}

output "clair_rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.clair_db.port
  sensitive   = false
}
