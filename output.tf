output "EC2_instance_ID" {
  description = "ID of project EC2_instance"
  value       = aws_instance.foo.id
}

output "Security_Group_ID" {
  description = "ID of project Security_Group"
  value       = aws_security_group.allow_ssh.id
}

output "EFS_volume_ID" {
  description = "ID of project EFS_volume"
  value       = aws_efs_file_system.foo.id
}

output "S3_Bucket_ID" {
  description = "ID of project S3_Bucket"
  value       = aws_s3_bucket.bucket.id
}

output "Subnet_ID" {
  description = "ID of project Subnet"
  value       = aws_subnet.tf_test_subnet.id
}