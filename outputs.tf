output "instance_public_ip" {
  description = "Public IP of the app server"
  value       = aws_instance.app.public_ip
}

output "ssh_command" {
  description = "Ready-made SSH command"
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${aws_instance.app.public_ip}"
}
