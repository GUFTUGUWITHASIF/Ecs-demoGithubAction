provider "aws" {

  access_key = "AKIA5UEC5Z6ABDKLYT52"
  secret_key = "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"
  region     = "ap-southeast-2"
}

resource "aws_vpc" "asif_vpc" {
  cidr_block          = "10.0.0.0/16"
  instance_tenancy    = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Asif Vpc"
  }
}

resource "aws_subnet" "asif_subnet1" {
  vpc_id                 = aws_vpc.asif_vpc.id
  cidr_block             = "10.0.1.0/24"
  availability_zone      = "ap-southeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "asif_subnet2" {
  vpc_id                 = aws_vpc.asif_vpc.id
  cidr_block             = "10.0.2.0/24"
  availability_zone      = "ap-southeast-2b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "asif_ig" {
  vpc_id = aws_vpc.asif_vpc.id

  tags = {
    Name = "Asif Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.asif_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.asif_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.asif_ig.id
  }

  tags = {
    Name = "Asif Public Route Table"
  }
}

resource "aws_security_group" "asif_sg" {
  name   = "Asif Sg"
  vpc_id = aws_vpc.asif_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table_association" "route1" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.asif_subnet1.id
}

resource "aws_route_table_association" "route2" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.asif_subnet2.id
}
resource "aws_ecr_repository" "asifapp" {
  name                  = "asif_app"
  image_tag_mutability  = "MUTABLE"
  image_scanning_configuration {
    scan_on_push         = true
  }
}
resource "aws_ecs_cluster" "asif_cluster" {
    name      = "asif_cluster"
}

resource "aws_ecs_service" "service" {
  name              = "asif_service"
  launch_type       = "FARGATE"
  cluster           = aws_ecs_cluster.asif_cluster.arn
  
  desired_count     = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  task_definition   = aws_ecs_task_definition.task.arn

  network_configuration {
    subnets                 = [aws_subnet.asif_subnet1.id, aws_subnet.asif_subnet2.id]
    security_groups         = [aws_security_group.asif_sg.id] 
    assign_public_ip        = true
  }
}
  
resource "aws_ecs_task_definition" "task" {
  family                    = "aws_task_definition"
  execution_role_arn        = "arn:aws:iam::936577453952:role/ecsTaskExecutionRole"
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                       = "256"
  memory                    = "512"
  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  
  container_definitions     = jsonencode([
    {
      name                  = "app_container"
      image                 = "936577453952.dkr.ecr.ap-southeast-2.amazonaws.com/ecs-task1:latest"
      essential             = true
  
      portMappings          = [
        {
          containerPort     = 80
          hostPort          = 80
        }
      ]
    }
  ])
}
