provider "aws" {
  region = local.region
}

locals {
  region = "us-east-2"
}

#######
# VPC
#######

resource "aws_vpc" "vpc_desafio1" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "Desafio1-vpc"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

resource "aws_internet_gateway" "gw_desafio1" {
  vpc_id = aws_vpc.vpc_desafio1.id

  tags = {
    Name = "gw_desafio1"
  }
}

#######
# Subnet VPC
#######

#Private Subnet
resource "aws_subnet" "subnet_private1_desafio1" {
  vpc_id     = aws_vpc.vpc_desafio1.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "subnet_private1_desafio1"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

#Private Subnet
resource "aws_subnet" "subnet_private2_desafio1" {
  vpc_id     = aws_vpc.vpc_desafio1.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "${local.region}b"

  tags = {
    Name = "subnet_private2_desafio1"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

#Public Subnet
resource "aws_subnet" "subnet_public1_desafio1" {
  vpc_id     = aws_vpc.vpc_desafio1.id
  cidr_block = "10.1.100.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "subnet_public1_desafio1"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

#Public Subnet
resource "aws_subnet" "subnet_public2_desafio1" {
  vpc_id     = aws_vpc.vpc_desafio1.id
  cidr_block = "10.1.101.0/24"
  availability_zone = "${local.region}b"

  tags = {
    Name = "subnet_public2_desafio1"
    Terraform = "true"
    Environment = "prd"
    Owner = "Marco Tulio Rangel"
  }
}

#######
# Network Interface 
#######

resource "aws_network_interface" "Ubuntu2004-01_eth01" {
  subnet_id     = aws_subnet.subnet_private1_desafio1.id
  #private_ip   = "10.1.1.10"

  tags = {
    Name        = "Desafio1-primary_network_interface"
    Terraform   = "true"
    Environment = "prd"
    Owner       = "Marco Tulio Rangel"
  }
}

#######
# EC2 
#######

resource "aws_instance" "Ubuntu2004-01" {
  ami           = "ami-0e877974e9bd4febb" #AMIName: Apache Web Server with Ubuntu 20.04-e5326cbd-2355-4541-a5ed-65d1caece007
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.Ubuntu2004-01_eth01.id
    device_index         = 0
  }

  tags = {
    Name        = "Ubuntu20.04-01"
    Terraform   = "true"
    Environment = "prd"
    Owner       = "Marco Tulio Rangel"
  }
}

#######
# S3 
#######

resource "aws_s3_bucket" "dati-marcotuliorangeldasilvacandido-desafio1" {
  bucket = "dati-marcotuliorangeldasilvacandido-desafio1"
  #acl    = "public-read-write"
  acl    = "private"
  
  tags = {
    Name        = "dati-marcotuliorangeldasilvacandido-desafio1"
    Terraform   = "true"
    Environment = "prd"
    Owner       = "Marco Tulio Rangel"
  }
}