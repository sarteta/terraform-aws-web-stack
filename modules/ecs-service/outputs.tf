output "service_name" {
  value = aws_ecs_service.this.name
}

output "cluster_arn" {
  value = local.cluster_arn
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "security_group_id" {
  value = aws_security_group.service.id
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
