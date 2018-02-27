provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    encrypt = true
    acl = "private"
  }
}

data "terraform_remote_state" "web-service" {
  backend = "s3"
  config {
    bucket = "chris-practice-${var.region}"
    key = "state"
    region = "${var.region}"
  }
}

module "web-service-module" {
  source   = "./module"
  name     = "web1"
  path     = "web1"
  cluster  = "${aws_ecs_cluster.chris-practice-cluster.id}"
  listener = "${aws_lb_listener.chris-practice-listener.arn}"
  priority = 100
  vpc      = "${var.vpc}"
}

module "web2-service-module" {
  source   = "./module"
  name     = "web2"
  path     = "web2"
  cluster  = "${aws_ecs_cluster.chris-practice-cluster.id}"
  listener = "${aws_lb_listener.chris-practice-listener.arn}"
  priority = 101
  vpc      = "${var.vpc}"
}

resource "aws_ecs_cluster" "chris-practice-cluster" {
  name = "tfpractice"
}

resource "aws_lb" "chris-practice-alb" {
  name     = "tfpractice"
  internal = false
  subnets  = ["${var.subnet1}", "${var.subnet2}"]
}

resource "aws_lb_target_group" "chris-practice-void-targetgroup" {
  name     = "tfpractice-void-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc}"
}

resource "aws_lb_listener" "chris-practice-listener" {
  load_balancer_arn = "${aws_lb.chris-practice-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.chris-practice-void-targetgroup.arn}"
    type             = "forward"
  }
}

resource "aws_launch_configuration" "chris-practice-launchconfig" {
  name          = "tfpractice-launchconfig"
  image_id      = "${var.image}"
  instance_type = "t2.micro"

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.chris-practice-cluster.name} >> /etc/ecs/ecs.config
EOF

  iam_instance_profile = "arn:aws:iam::690350436795:instance-profile/ecsInstanceRole"
}

resource "aws_autoscaling_group" "chris-practice-asgroup" {
  name                 = "tfpractice-asgroup"
  availability_zones   = ["${var.az1}", "${var.az2}"]
  launch_configuration = "${aws_launch_configuration.chris-practice-launchconfig.name}"
  min_size             = 1
  max_size             = 1
}
