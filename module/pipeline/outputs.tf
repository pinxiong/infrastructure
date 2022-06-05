output "repository_id" {
  description = "The created repository id."
  value       = aws_codecommit_repository.repository.id
}

output "repository_arn" {
  description = "The created repository arn."
  value       = aws_codecommit_repository.repository.arn
}

output "repository_name" {
  description = "The created repository name."
  value       = aws_codecommit_repository.repository.repository_name
}

output "default_branch" {
  description = "The default branch name of created repository."
  value       = aws_codecommit_repository.repository.default_branch
}

output "clone_url_http" {
  description = "The URL to use for cloning the repository over HTTPS."
  value       = aws_codecommit_repository.repository.clone_url_http
}

output "clone_url_ssh" {
  description = "The URL to use for cloning the repository over SSH."
  value       = aws_codecommit_repository.repository.clone_url_ssh
}
