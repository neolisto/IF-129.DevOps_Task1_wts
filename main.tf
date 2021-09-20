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

// creating AWS key resource for ssh-connect
resource "aws_key_pair" "ec2_keys" {
  key_name = "aws_key"
  public_key = file("aws_key.pub")
}

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

// connection subnet with routing table
resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id = aws_subnet.project_subnet.id
  route_table_id = aws_route_table.prod-public-crt.id
}

/*
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
----------------------------------- PRODUCTION ENVIRONMENT CONFIGURATION ------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
*/

// creating Security group for MySQL database server
resource "aws_security_group" "mysql_database_server" {
  name        = "allow_mysql"
  description = "Allow mysql inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.112/32"]
  }

  ingress    {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.113/32"]
  }

  ingress    {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.114/32"]
  }

  ingress    {
    from_port        = 8111
    to_port          = 8111
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

// creating instance - MySQL database server
resource "aws_instance" "mysql_db_srv" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.micro"
  private_ip = "10.0.0.111"
  subnet_id = aws_subnet.project_subnet.id
  vpc_security_group_ids = [aws_security_group.mysql_database_server.id]

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("mysql_db_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    CI_CD_IP  = aws_instance.ci_cd.private_ip
    AGENT_NAME = "mysql_db_server"
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
    cidr_blocks      = ["10.0.0.114/32"]
  }

  ingress    {
    from_port        = 8111
    to_port          = 8111
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress    {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.114/32"]
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

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("be_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    DB_SRV_IP = aws_instance.mysql_db_srv.private_ip
    CI_CD_IP  = aws_instance.ci_cd.private_ip
    AGENT_NAME = "be1_server"
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

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("be_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    DB_SRV_IP = aws_instance.mysql_db_srv.private_ip
    CI_CD_IP  = aws_instance.ci_cd.private_ip
    AGENT_NAME = "be2_server"
  })

  tags = {
    Name = "be2_server"
  }
}

// creating nginx load-balancer security group
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

// creating instance - nginx-load-balancer
resource "aws_instance" "nginx_balancer" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.loadbalancer.id]
  private_ip = "10.0.0.114"
  subnet_id = aws_subnet.project_subnet.id

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("lb_srv_startup.sh.tpl", {
    BE1_SRV_IP = aws_instance.be1_srv.private_ip
    BE2_SRV_IP = aws_instance.be2_srv.private_ip
  })

  tags = {
    Name = "nginx_loadbalancer"
  }
}

/*
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
----------------------------------- TESTING ENVIRONMENT CONFIGURATION ---------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
*/

// creating of CI/CD server security group
resource "aws_security_group" "ci_cd" {
  name        = "allow_ci_cd"
  description = "Allow traffic to/from CI/CD server"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 8111
    to_port          = 8111
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
    Name = "connection pattern for CI/CD server"
  }
}

// creating instance - CI/CD server (TeamCity)
resource "aws_instance" "ci_cd" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.ci_cd.id]
  private_ip = "10.0.0.115"
  subnet_id = aws_subnet.project_subnet.id

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("ci_cd_server_startup.sh.tpl", {})

  tags = {
    Name = "CI/CD server (TeamCity)"
  }
}

// creating Security group for MySQL test server
resource "aws_security_group" "mysql_test_server" {
  name        = "allow_test_mysql"
  description = "Allow mysql inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

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

  ingress    {
    from_port        = 8111
    to_port          = 8111
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
    Name = "connection pattern for mysql test server"
  }
}

// creating MySQL database test server
resource "aws_instance" "mysql_test_srv" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.micro"
  private_ip = "10.0.0.117"
  subnet_id = aws_subnet.project_subnet.id
  vpc_security_group_ids = [aws_security_group.mysql_test_server.id]

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("mysql_db_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    CI_CD_IP  = aws_instance.ci_cd.private_ip
    AGENT_NAME = "mysql_test_server"
  })

  tags = {
    Name = "mysql_test_server"
  }
}

// creating Security group for WEB-test-server (BE+FE)
resource "aws_security_group" "be_test_sg" {
  name        = "allow_test_web"
  description = "Allow web inbound traffic"
  vpc_id = aws_vpc.default.id

  ingress    {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress    {
    from_port        = 8111
    to_port          = 8111
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
    Name = "connection pattern for web-test-server"
  }
}


// creating instance - BE test server
resource "aws_instance" "be_test_srv" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.small"
  vpc_security_group_ids = [aws_security_group.be_test_sg.id]
  private_ip = "10.0.0.116"
  subnet_id = aws_subnet.project_subnet.id

  key_name = "aws_key"
  connection {
    type        = "ssh"
    host        = self.public_ip
    user = "ubuntu"
    private_key = file("aws_key")
  }

  user_data = templatefile("be_srv_startup.sh.tpl", {
    DATASOURCE_USERNAME = var.DATASOURCE_USERNAME
    DATASOURCE_PASSWORD = var.DATASOURCE_PASSWORD
    DB_SRV_IP = aws_instance.mysql_test_srv.private_ip
    CI_CD_IP  = aws_instance.ci_cd.private_ip
    AGENT_NAME = "be_test_server"
  })

  tags = {
    Name = "be_test_server"
  }
}

# creating Terraform outputs
output "nginx_load_balancer_public_ip" {
  value = aws_instance.nginx_balancer.public_ip
  description = "Public IP of your nginx load-balancer server"
}

output "be1_server_public_ip" {
  value = aws_instance.be1_srv.public_ip
  description = "Public IP of your web-server #1"
}

output "be2_server_public_ip" {
  value = aws_instance.be2_srv.public_ip
  description = "Public IP of your web-server #2"
}

output "mysql_server_public_ip" {
  value = aws_instance.mysql_db_srv.public_ip
  description = "Public IP of your web-server #2"
}

output "ci_cd_public_ip" {
  value = aws_instance.ci_cd.public_ip
  description = "Public IP of your CI/CD server"
}

output "mysql_test_server_public_ip" {
  value = aws_instance.mysql_test_srv.public_ip
  description = "Public IP of your MySQL-test server"
}

output "be_test_server_public_ip" {
  value = aws_instance.be_test_srv.public_ip
  description = "Public IP of your test web-server"
}