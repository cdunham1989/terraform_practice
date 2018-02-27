resource "aws_ecr_repository" "chris-practice-ecrrepository" {
  name = "${var.name}-repository"
}

resource "aws_ecs_task_definition" "web-task-definition" {
  family                = "${var.name}-taskdef"
  container_definitions = "${data.template_file.web-service.rendered}"
}

resource "aws_ecs_service" "web-service" {
  name            = "${var.name}-service"
  cluster         = "${var.cluster}"
  task_definition = "${aws_ecs_task_definition.web-task-definition.arn}"
  desired_count   = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.chris-practice-targetgroup.arn}"
    container_name   = "${var.name}-container"
    container_port   = "80"
  }
}

resource "aws_lb_target_group" "chris-practice-targetgroup" {
  name     = "${var.name}-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc}"
}

resource "aws_lb_listener_rule" "chris-practice-listenerrule" {
  listener_arn = "${var.listener}"
  priority     = "${var.priority}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.chris-practice-targetgroup.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/${var.path}/*"]
  }
}

data "template_file" "web-service" {
  template = "${file("task-definitions/service.json")}"

  vars {
    ecrimagelocation = "${aws_ecr_repository.chris-practice-ecrrepository.repository_url}"
    logconfiguration = "${aws_cloudwatch_log_group.chris-practice-loggroup.name}"
    containername    = "${var.name}-container"
  }
}

resource "aws_cloudwatch_log_group" "chris-practice-loggroup" {
  name = "${var.name}-service"
}
