output "ecs_cluster_id" {
  description = "The ecs cluster id."
  value       = aws_ecs_cluster.ecs.id
}

output "ecs_cluster_name" {
  description = "The ecs cluster name."
  value       = aws_ecs_cluster.ecs.name
}

output "ecs_service_arn" {
  description = "The ecs service arn."
  value       = aws_ecs_service.ecs.id
}

output "ecs_service_name" {
  description = "The ecs service name."
  value       = aws_ecs_service.ecs.name
}

