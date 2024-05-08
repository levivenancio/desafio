provider "aws" {
 region = "us-east-1"
 shared_config_files      = [".aws/config"]
 shared_credentials_files = [".aws/config"]
}

resource "aws_efs_file_system" "efs" {
  creation_token = "decathlom"

  tags = {
    Name = "deca_bikes"
  }
}

resource "aws_instance" "ec2_instance1" {
   count = 2
    ami           = "ami-07caf09b362be10b8"
    instance_type = "t2.micro"
    subnet_id     = "subnet-047e6cd5af59e323c" # ID da Subnet
    vpc_security_group_ids = ["${aws_security_group.instance_sg.id}"]

    key_name = "vockey"

     user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd git
              sudo systemctl start httpd
              sudo systemctl enable httpd
              sudo yum install -y amazon-efs-utils
              sudo mkdir /mnt/efs
              sudo mount -t efs ${aws_efs_file_system.efs.id}:/ /mnt/efs
              sudo rm -rf /var/www/html
              sudo git clone https://github.com/FofuxoSibov/sitebike /mnt/efs
              sudo ln -s /mnt/efs /var/www/html
              EOF

    tags = {
      Name = "server-${count.index}"
    }
}

resource "aws_security_group" "instance_sg" {
  name        = "group-sec"
  description = "libera ssh http efs"
  vpc_id      = "vpc-0d32832a28c4905bd"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "github_sha" {}