provider "aws" {
  region = "us-east-1"  # Change the region if needed
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer_key"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public SSH key
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y java-1.8.0-openjdk
              sudo amazon-linux-extras install java-openjdk11
              sudo yum install -y git
              git clone https://github.com/example/log4j-vulnerable-app.git /home/ec2-user/log4j-vulnerable-app
              cd /home/ec2-user/log4j-vulnerable-app
              ./gradlew build
              ./gradlew run
              EOF

  tags = {
    Name = "Log4jVulnerableInstance"
  }
}

output "instance_ip" {
  value = aws_instance.web.public_ip
}
