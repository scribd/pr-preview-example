resource "aws_appmesh_virtual_gateway" "pr-preview-example-com" {
  name      = "pr-preview-example-com"
  mesh_name = aws_appmesh_mesh.pr-preview-mesh.name

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }
}

resource "aws_ecs_task_definition" "pr-preview-example-com" {
  family        = "pr-preview-example-com"
  task_role_arn = aws_iam_role.pr-preview-instance.arn
  network_mode  = "awsvpc"

  volume {
    name = "var_log"

    docker_volume_configuration {
      scope = "task"
    }
  }

  container_definitions = file("task-definitions/pr-preview-example-com.json")
}


resource "aws_ecs_service" "pr-preview-example-com" {
  name                               = "pr-preview-example-com"
  cluster                            = aws_ecs_cluster.pr-preview.id
  task_definition                    = aws_ecs_task_definition.pr-preview-example-com.arn
  force_new_deployment               = true
  desired_count                      = 3
  deployment_minimum_healthy_percent = 67
  wait_for_steady_state              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = ["subnet-12345", "subnet-67890"]
    security_groups  = [aws_security_group.pr-preview-example-com.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pr-preview-example-com-80.arn
    container_name   = "envoy"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pr-preview-example-com-9901.arn
    container_name   = "envoy"
    container_port   = 9901
  }
}


resource "aws_lb" "pr-preview-example-com" {
  name               = "pr-preview-example-com"
  load_balancer_type = "application"
  subnets            = ["subnet-12345", "subnet-67890"]
  security_groups    = [aws_security_group.pr-preview-example-com.id]
  internal           = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_lb_listener" "pr-preview-example-com-80" {
  load_balancer_arn = aws_lb.pr-preview-example-com.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pr-preview-example-com-80.arn
  }
}

resource "aws_lb_listener" "pr-preview-example-com-443" {
  load_balancer_arn = aws_lb.pr-preview-example-com.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.pr-preview-example-com-wildcard-tls.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pr-preview-example-com-80.arn
  }
}

resource "aws_lb_target_group" "pr-preview-example-com-80" {
  name                 = "pr-preview-example-com-80"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = "vpc-12345"
  slow_start           = 30
  deregistration_delay = 60

  # This way we can see envoy even if the virtual service isn't available
  health_check {
    enabled = true
    port    = 9901
    path    = "/ready"
  }
}

resource "aws_lb_listener" "pr-preview-example-com-9901" {
  load_balancer_arn = aws_lb.pr-preview-example-com.arn
  port              = 9901
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pr-preview-example-com-9901.arn
  }
}

resource "aws_lb_target_group" "pr-preview-example-com-9901" {
  name                 = "pr-preview-example-com-9901"
  port                 = 9901
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.staging.id
  slow_start           = 30
  deregistration_delay = 60

  health_check {
    enabled = true
    path    = "/ready"
  }
}

