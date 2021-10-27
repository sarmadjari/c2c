terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

/*==== The VPC ======*/
resource "aws_vpc" "c2c-vpc" {
  cidr_block       = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "c2c-vpc"
    Application = "c2c"
  }
}
/*==== Subnets ======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "c2c-internet-gateway" {
  vpc_id = aws_vpc.c2c-vpc.id
  tags = {
    Name = "c2c-internet-gateway"
    Application = "c2c"
  }
}
/* Elastic IP for NAT */
/*resource "aws_eip" "c2c-elastic-ip" {
  vpc        = true
  depends_on = [aws_internet_gateway.c2c-internet-gateway]
   tags = {
   Name        = "c2c-elastic-ip"
   Application = "c2c"
 }
}*/
/* NAT */
/*resource "aws_nat_gateway" "c2c-nat-gateway" {
  allocation_id = aws_eip.c2c-elastic-ip.id
  subnet_id     = aws_subnet.c2c-public-subnet.id
  depends_on    = [aws_internet_gateway.c2c-internet-gateway]
  tags = {
    Name        = "c2c-nat-gateway"
    Application = "c2c"
  }
}*/
/* Public subnet */
resource "aws_subnet" "c2c-public-subnet" {
  vpc_id                  = aws_vpc.c2c-vpc.id
  cidr_block                = "10.0.0.0/24"
  tags = {
    Name        = "c2c-public-subnet"
    Application = "c2c"
  }
}
/* Route Table*/
resource "aws_route_table" "c2c-route-table" {
  vpc_id = aws_vpc.c2c-vpc.id
  #depends_on    = [aws_internet_gateway.c2c-internet-gateway,aws_nat_gateway.c2c-nat-gateway]

  route = [
    {
      cidr_block = "0.0.0.0/0"
      ipv6_cidr_block  = ""
      gateway_id = aws_internet_gateway.c2c-internet-gateway.id
      # nat_gateway_id = aws_nat_gateway.c2c-nat-gateway.id
      nat_gateway_id  = ""
      carrier_gateway_id  = ""
      destination_prefix_list_id  = ""
      egress_only_gateway_id  = ""
      instance_id  = ""
      local_gateway_id  = ""
      nat_gateway_id  = ""
      network_interface_id  = ""
      transit_gateway_id  = ""
      vpc_endpoint_id  = ""
      vpc_peering_connection_id  = ""
    },
    {
     cidr_block = "10.0.0.0/24"
     ipv6_cidr_block  = ""
     #gateway_id = aws_internet_gateway.c2c-internet-gateway.id
     gateway_id  = ""
     #nat_gateway_id = aws_nat_gateway.c2c-nat-gateway.id
     nat_gateway_id = ""
     carrier_gateway_id  = ""
     destination_prefix_list_id  = ""
     egress_only_gateway_id  = ""
     instance_id  = ""
     local_gateway_id  = ""
     nat_gateway_id  = ""
     network_interface_id  = ""
     transit_gateway_id  = ""
     vpc_endpoint_id  = ""
     vpc_peering_connection_id  = ""
   },
  ]
  tags = {
    Name        = "c2c-route-table"
    Application = "c2c"
  }
}
resource "aws_route_table_association" "c2c-route-table-association" {
    depends_on    = [aws_lb.c2c-network-load-balancer]
    subnet_id      = aws_subnet.c2c-public-subnet.id
    route_table_id = aws_route_table.c2c-route-table.id
}
/*==== Security Group ======*/
/* Security Group */
resource "aws_security_group" "c2c-security-group" {
    name        = "c2c-security-group"
    description = "Control Trafic to the C2C Container"
    vpc_id      = aws_vpc.c2c-vpc.id

  egress = [
    {
      description      = "Allow Trafic to the Internet"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self = false
    }
  ]
  ingress = [
    {
      description      = "Alle Traffic from the Subnet only"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = [aws_subnet.c2c-public-subnet.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self = false
    }
 ]
}

/*==== Network Load Balancer ======*/
/* Network Load Balancer */
resource "aws_lb" "c2c-network-load-balancer" {
  name               = "c2c-network-load-balancer"
  # dns_name           = "c2c"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.c2c-public-subnet.*.id
  enable_deletion_protection = false

  tags = {
    Name        = "c2c-network-load-balancer"
    Application = "c2c"
  }
}
/* Target Group */
resource "aws_lb_target_group" "c2c-target-group" {
  name        = "c2c-target-group"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.c2c-vpc.id
  depends_on    = [aws_lb.c2c-network-load-balancer]

  tags = {
    Name        = "c2c-target-group"
    Application = "c2c"
  }
}
/* Listener */
resource "aws_lb_listener" "c2c-listener" {
  load_balancer_arn = aws_lb.c2c-network-load-balancer.arn
  port              = "80"
  protocol          = "TCP"
  depends_on    = [aws_lb_target_group.c2c-target-group]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.c2c-target-group.arn
  }
  tags = {
    Name        = "c2c-listener"
    Application = "c2c"
  }
}
/*==== AWS ESC Fargate ======*/
/* ESC Cluster */
resource "aws_ecs_cluster" "c2c-cluster" {
  name = "c2c-cluster"
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 1
    weight            = 1
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = {
    Name        = "c2c-cluster"
    Application = "c2c"
  }
}
/* ESC Task Definition */
resource "aws_ecs_task_definition" "c2c-taskdefinition" {
  family                    = "c2c-taskdefinition"
  requires_compatibilities  = ["FARGATE"]
  cpu                       = 256
  memory                    = 512
  network_mode              = "awsvpc"
  depends_on                = [aws_ecs_cluster.c2c-cluster]
  lifecycle {
    create_before_destroy = true
  }
  container_definitions = jsonencode([
    {
      name      = "c2c"
      image     = "ghcr.io/sarmadjari/c2c:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  tags = {
    Name        = "c2c-taskdefinition"
    Application = "c2c"
  }
}
/* ESC Service */
resource "aws_ecs_service" "c2c-service" {
  name            = "c2c-service"
  cluster         = aws_ecs_cluster.c2c-cluster.id
  task_definition = aws_ecs_task_definition.c2c-taskdefinition.arn
  desired_count   = 1
  depends_on    = [aws_ecs_cluster.c2c-cluster,aws_lb.c2c-network-load-balancer]

  network_configuration{
    subnets             = aws_subnet.c2c-public-subnet.*.id
    assign_public_ip    = true
    security_groups     = [aws_security_group.c2c-security-group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.c2c-target-group.arn
    container_name   = "c2c"
    container_port   = 80
  }
  tags = {
    Name        = "c2c-service"
    Application = "c2c"
  }
}