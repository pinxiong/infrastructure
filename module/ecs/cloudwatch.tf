data "template_file" "loadBalancer" {
  template   = format("app/%s/%s", aws_lb.ecs-service.name, split("/", aws_lb.ecs-service.arn)[3])
  depends_on = [
    aws_lb.ecs-service
  ]
}

# Create cloudwatch dashboard
resource "aws_cloudwatch_dashboard" "golang-web" {
  dashboard_name = "Dashboard"
  dashboard_body = templatefile("${path.module}/resources/dashboard_body.json", {
    loadBalancer   = data.template_file.loadBalancer.rendered
    region         = local.region
    ecsClusterName = aws_ecs_cluster.ecs.name
    ecsServiceName = aws_ecs_service.ecs.name
  })
  depends_on = [
    aws_lb.ecs-service,
    aws_lb_target_group.ecs-service
  ]
}

