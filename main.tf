terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {}

// setting user's name for eSchool database
variable "DATASOURCE_USERNAME" {}

// setting password for user in eSchool database
variable "DATASOURCE_PASSWORD" {}

// creating of AWS VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "prod VPC"
  }
}

// creating AWS gateway and attaching him to VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "prod-igw"
  }
}

// creating subnet for VM's
resource "aws_subnet" "project_subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.default.id
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"

  tags = {
    Name = "project subnet"
  }
}

// creating routing table for VPC instances
resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-public-crt"
  }
}

// connection subnet with routing table
resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id = aws_subnet.project_subnet.id
  route_table_id = aws_route_table.prod-public-crt.id
}

// creating Security group for MySQL database server
resource "aws_security_group" "mysql_database_server" {
  name        = "allow_mysql"
  description = "Allow mysql inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.112/24"]
  }

  ingress    {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.113/24"]
  }

  ingress    {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.114/24"]
  }

  egress    {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "connection pattern for mysql server"
  }
}

// creating instance - MySQL database server
resource "aws_instance" "mysql_db_srv" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.micro"
  private_ip = "10.0.0.111"
  subnet_id = aws_subnet.project_subnet.id
  vpc_security_group_ids = [aws_security_group.mysql_database_server.id]

  user_data = templatefile("mysql_db_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
  })

  tags = {
    Name = "mysql_database_server"
  }
}

// creating Security group for WEB-server (BE+FE)
resource "aws_security_group" "be_server_sg" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.114/24"]
  }

  ingress    {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.114/24"]
  }

  egress    {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "connection pattern for web server"
  }
}

// creating instance - WEB-server (BE+FE)
resource "aws_instance" "be1_srv" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.small"
  vpc_security_group_ids = [aws_security_group.be_server_sg.id]
  private_ip = "10.0.0.112"
  subnet_id = aws_subnet.project_subnet.id

  user_data = templatefile("be_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    DB_SRV_IP = aws_instance.mysql_db_srv.private_ip
  })

  tags = {
    Name = "be1_server"
  }
}

// creating instance - WEB-server (BE+FE)
resource "aws_instance" "be2_srv" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.small"
  vpc_security_group_ids = [aws_security_group.be_server_sg.id]
  private_ip = "10.0.0.113"
  subnet_id = aws_subnet.project_subnet.id

  user_data = templatefile("be_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    DB_SRV_IP = aws_instance.mysql_db_srv.private_ip
  })

  tags = {
    Name = "be2_server"
  }
}

resource "aws_security_group" "loadbalancer" {
  name        = "allow_LB"
  description = "Allow traffic to/from loadbalancer"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 80
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress    {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress    {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "connection pattern for loadbalancer"
  }
}

// creating instance - nginx-loadbalancer
resource "aws_instance" "nginx_balancer" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.loadbalancer.id]
  private_ip = "10.0.0.114"
  subnet_id = aws_subnet.project_subnet.id

  user_data = templatefile("lb_srv_startup.sh.tpl", {
    BE1_SRV_IP = aws_instance.be1_srv.private_ip
    BE2_SRV_IP = aws_instance.be2_srv.private_ip
  })

  tags = {
    Name = "nginx_loadbalancer"
  }
}