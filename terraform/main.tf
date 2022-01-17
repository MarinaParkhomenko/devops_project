provider "aws" {
region = "us-east-1"

}

data "aws_ami" "ubuntu" {
most_recent = true

 filter {
  name = "name"
  values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
 }

 filter { 
  name = "virtualization-type"
  values = ["hvm"]
 }

 owners = ["099720109477"] #Canonical
}

resource "aws_eip" "lb" {
  instance = aws_instance.my_site.id
  vpc      = true
}

resource "aws_instance" "my_site" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name = "instance_key"

  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("aws_key.pem")
      host        = self.public_ip
    }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.my_site.public_ip}, --private-key ${"aws_key.pem"} pb.yml"
  }


  tags =  {
   Name = "my_site"
 }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow web inbound traffic"

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22   
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

  output "Elastic_IP" {
   value = aws_instance.my_site.public_ip
 }
