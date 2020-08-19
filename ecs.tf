resource "aws_ecs_cluster" "cluster" {
  name = "and-academy"
}

resource "aws_alb" "main" {
  name            = "academy"
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.main.id]
}

resource "aws_alb_target_group" "main" {
  name        = "academy"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_ecs_service" "main" {
  name            = "academy"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 5
  launch_type     = "FARGATE"
  #iam_role        = aws_iam_role.main.arn
  network_configuration {
    #assign_public_ip = true
    security_groups = [aws_security_group.main.id]
    subnets         = module.vpc.private_subnets
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = "first"
    container_port   = 80
  }
  depends_on = [
    aws_alb_listener.main
  ]
}

resource "aws_security_group" "main" {
  vpc_id = module.vpc.vpc_id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.main.arn
  container_definitions = jsonencode([{
    name : "first",
    image : "tutum/hello-world",
    cpu : 256,
    memory : 512,
    essential : true,
    readonly_root_filesystem = false,
    portMappings : [
      {
        containerPort : 80,
        hostPort : 80
      }
    ]
  }])
}

resource "aws_iam_role" "main" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "main" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "main" {
  policy_arn = aws_iam_policy.main.arn
  role       = aws_iam_role.main.name
}