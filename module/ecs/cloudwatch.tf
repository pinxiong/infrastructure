data "template_file" "lb" {
  template   = format("app/%s/%s", aws_lb.ecs_service.name, split("/", aws_lb.ecs_service.arn)[3])
  depends_on = [
    aws_lb.ecs_service
  ]
}

# Create cloudwatch dashboard
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "Dashboard"
  dashboard_body = templatefile("${path.module}/resources/dashboard_body.json", {
    loadBalancer   = data.template_file.lb.rendered
    region         = local.region
    ecsClusterName = aws_ecs_cluster.ecs.name
    ecsServiceName = aws_ecs_service.ecs.name
  })
  depends_on = [
    aws_lb.ecs_service,
    aws_lb_target_group.ecs_service
  ]
}