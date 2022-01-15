<h1 align="center">DevOps Project</h1>

<h2 align="center">Running the instance</h2>
Terraform is being used for this purpose. Terraform lets us create the infrastructure through the code.
<br>
Setting up ubuntu instance
```tf
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
 ``` 
 <br>
 Using `provisioner "local-exec"` tu run Ansible Playbook
 ```tf
 provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.my_site.public_ip}, --private-key ${"aws_key.pem"} pb.yml"
  }
 ```
 <br>
 Customizing `aws_security_group` 
 ```tf
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
 ```
 <br>
 
 <h2 align="center">Using Ansible Playbook</h2>
 With Ansible Playbook tasks we can run commands to setup Docker. Watchtower lets us push new image to your docker hub, thereby updating current running container.
  ```tf
 ---
- name: Run Docker container
  hosts: all
  remote_user: ubuntu
  become: yes

  tasks:
  - name: Update packages
    apt:
      update_cache: yes
  - name: Install curl
    apt:
      pkg:
      - curl
  - name: Install docker
    shell:
      "curl -sSL https://get.docker.com/ | sh"
  - name: Run docker container
    shell:
      "sudo docker run -d --name my_site -p 80:80 dockermarina02/my_site_docker"
  - name: Run docker container
    shell:
      "sudo docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup -i 10"
 ```
 <br>
 
  <h2 align="center">Using Github Actions</h2>
 With help of Github Actions we are able to build a pipeline. Following pipeline runs Lint check, logins into DockerHub and pushes the code to Docker.
 ```tf
 name: Running Docker Image

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    
    - name: Lint Dockerfile
      uses: luke142367/Docker-Lint-Action@v1.0.0
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Login in Docker
      uses: docker/login-action@v1.12.0
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD  }}
        
    - name: Build and push action
      id: docker_build
      uses: docker/build-push-action@v2
      with:
          push: true
          tags: dockermarina02/my_site_docker:latest
 ```
 <br>
 
 <h2 align="center">Solution monitoring tools</h2>
 AWS provides AWS CloudWatch service that can be used as monitoring tool for checking instance status.
 <br>
 
 < <h2 align="center">Assigning DNS name</h2>
 AWS provides Route53 service which lets us assing DNS name to the IP adress of the EC2 instance.
