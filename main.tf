provider "aws" {
  region = "us-east-2"  # Change the region if needed
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#resource "aws_key_pair" "deployer_key" {
#  key_name   = "ec2-key-pair"
#  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public SSH key
#}

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
    from_port   = 8080
    to_port     = 8080
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
  ami           = data.aws_ami.amazon_linux.id # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name   = "ec2-key-pair"
  security_groups = [aws_security_group.allow_ssh.name]

user_data = <<-EOF
            #!/bin/bash
            sudo -i
            yum update -y
            amazon-linux-extras install epel
            yum install java-1.8.0-openjdk
            amazon-linux-extras install java-openjdk11
            yum install -y git
            wget -c http://services.gradle.org/distributions/gradle-8.8-all.zip -P /tmp
            unzip /tmp/gradle-8.8-all.zip -d /opt
            ln -s /opt/gradle-8.8 /opt/gradle
            printf "export GRADLE_HOME=/opt/gradle\nexport PATH=\$PATH:\$GRADLE_HOME/bin\n" > /etc/profile.d/gradle.sh
            source /etc/profile.d/gradle.sh
            git clone https://github.com/s1-slappey/cnapp_demo.git /home/ec2-user/app
            cd /home/ec2-user/app/log4j-app
            gradle build
            gradle run
            EOF


  tags = {
    Name = "Log4jVulnerableInstance"
  }
}

output "instance_ip" {
  value = aws_instance.web.public_ip
}
