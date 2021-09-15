terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {}

variable "DATASOURCE_USERNAME" {}

variable "DATASOURCE_PASSWORD" {}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "prod VPC"
  }

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "prod-igw"
  }
}

resource "aws_subnet" "project_subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.default.id
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"

  tags = {
    Name = "project subnet"
  }
  #  depends_on = [aws_internet_gateway.gw]
}

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

resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id = aws_subnet.project_subnet.id
  route_table_id = aws_route_table.prod-public-crt.id
}

/*
resource "aws_nat_gateway" "router" {
  allocation_id = aws_eip.test.id
  subnet_id     = aws_subnet.project_subnet.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}
*/

resource "aws_security_group" "mysql_database_server" {
  name        = "allow_mysql"
  description = "Allow mysql inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
      from_port        = 3306
      to_port          = 3306
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
    Name = "connection pattern for mysql server"
  }
}

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

resource "aws_eip" "test" {
  vpc = true

  instance = aws_instance.mysql_db_srv.id
  associate_with_private_ip = "10.0.0.111"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_security_group" "be_server_sg" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
      from_port        = 8080
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
    Name = "connection pattern for web server"
  }
}

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
