# IF-129.DevOps_Task1_wts
SoftServe DevOps Demo №1 (what to show)

It's my Terraform project for creating infrastructure on cloud servers of Amazon Web Services.

This is a project of eSchool - is a school management web application based on Spring Boot and developed as graduation project at SoftServe IT Academy.

Software required to run this application:
1. Java
2. MySQL Server
3. Git

# Project schem:

![Image of schem](https://i.imgur.com/vZRU6z7.jpg)

# Installation process via Terraform:
#### 0. clone this project by git clone:
```
git clone https://github.com/neolisto/IF-129.DevOps_Task1_wts.git
```

#### 1. change your work directory to project directory:
```
cd IF-129.DevOps_Task1_wts/
```

#### 2. create environment variables with your AWS credentials:
```
export AWS_ACCESS_KEY_ID=<your_access_key>
export AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
export AWS_DEFAULT_REGION=<your_aws_region>
```

#### 3. generate ssh key-pair with name aws_key by using ssh-keygen:
```
ssh-keygen -f aws_key
```

#### 4. run terraform init and terraform plan/apply:
```
terraform init
terraform apply
```

#### 5. set a password and username of database service account which will be used by web-application for MySQL requests:
```
var.DATASOURCE_PASSWORD
  Enter a value:<user_password>

var.DATASOURCE_USERNAME
  Enter a value:<username>
```

# Enjoy the process!
