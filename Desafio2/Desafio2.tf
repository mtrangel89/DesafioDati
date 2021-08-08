provider "aws" {
  region = local.region
}

locals {
  region = "us-east-2"
}

#######
# VPC
#######

resource "aws_vpc" "vpc_desafio2" {
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "Desafio2-vpc"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

resource "aws_internet_gateway" "gw_desafio2" {
  vpc_id = aws_vpc.vpc_desafio2.id

  tags = {
    Name = "gw_desafio2"
  }
}

#######
# Subnet VPC
#######

resource "aws_subnet" "subnet_private_desafio2" {
  vpc_id     = aws_vpc.vpc_desafio2.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "subnet_private_desafio2"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

resource "aws_subnet" "subnet_public_desafio2" {
  vpc_id     = aws_vpc.vpc_desafio2.id
  cidr_block = "10.2.100.0/24"
  
  availability_zone = "${local.region}a"

  tags = {
    Name = "subnet_public_desafio2"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

#######
# Network Interface 
#######

resource "aws_network_interface" "AWS-Linux2-01_eth01" {
  subnet_id   = aws_subnet.subnet_private_desafio2.id
  #private_ip = "10.2.1.10"

  tags = {
    Name = "Desafio2-primary_network_interface"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

#######
# EC2 
#######

resource "aws_instance" "AWS-Linux2-01" {
  ami           = "ami-0443305dabd4be2bc" # us-east-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.AWS-Linux2-01_eth01.id
    device_index         = 0
  }

  tags = {
    Name = "AWS-Linux2-01"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}


#######
# Network LoadBalancer
#######

resource "aws_lb" "lb-desafio2" {
  name               = "lb-desafio2"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.subnet_public_desafio2.id]

  enable_deletion_protection = false

  tags = {
    Terraform   = "true"
    Environment = "prd"
    Owner       = "Marco Tulio Rangel"
  }
}





#######
# AWS Autoscaling group 
#######

resource "aws_placement_group" "pg_desafio2" {
  name     = "pg_desafio2"
  strategy = "spread"
}

data "aws_ami" "amazon" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Amazon Linux 2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["823765613917"] # Amazon
}

resource "aws_launch_configuration" "lc_desafio2" {
  name   = "desafio2"
  image_id      = data.aws_ami.amazon.id
  instance_type = "t2.micro"
  user_data = "${file("install_apache.sh")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_desafio2" {
  name                      = "asg_desafio2"
  max_size                  = 3
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  placement_group           = aws_placement_group.pg_desafio2.id
  launch_configuration      = aws_launch_configuration.lc_desafio2.name
  vpc_zone_identifier       = [aws_subnet.subnet_private_desafio2.id]
  termination_policies      = ["OldestInstance"]
  target_group_arns         = [aws_lb_target_group.tg-desafio2.arn]

  initial_lifecycle_hook {
      name                  = "startup_desafio2"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({"DATI" = "asg_desafio2 - startup"})
    }
  
  tag {
    key                 = "terraform"
    value               = "true"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "terraform"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_desafio2" {
  autoscaling_group_name = aws_autoscaling_group.asg_desafio2.name
}

resource "aws_lb_listener" "http80" {
  load_balancer_arn = aws_lb.lb-desafio2.arn
  port              = "80"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-desafio2.arn
  }
}
resource "aws_lb_target_group" "tg-desafio2" {
  name     = "tg-desafio2"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc_desafio2.id
}

variable "lb_tg_arn" {
  type    = string
  default = ""
}
variable "lb_tg_name" {
  type    = string
  default = ""
}

#data "aws_lb_target_group" "tg-desafio2" {
#    arn  = var.lb_tg_arn
#    name = var.lb_tg_name
#}
