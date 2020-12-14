# Configure the AWS Provider
provider "aws" {
    region = "eu-central-1" # Frankfurt Zone
    access_key = "AKIAUL77FUUDZZNG3W6C"
    secret_key = "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"
}


# 1. Create vpc - Virtual Private Cloud
resource "aws_vpc" "fursa" {
  cidr_block = "10.30.0.0/16" # the netmask here is 255.255.0.0
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.fursa.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "test-route-table" {
  vpc_id = aws_vpc.fursa.id

  route {
    cidr_block = "0.0.0.0/0" #IPv4
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0" #IPv6
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "fursa"
  }
}

# 4. Create a Subnet 

resource "aws_subnet" "fursa-subnet" {
  vpc_id            = aws_vpc.fursa.id
  cidr_block        = var.subnets[0] # Class C: 255.255.255.0 
  availability_zone = "eu-central-1a" # Availability Zone 
  tags = {
    Name = "fursa-subnet"
  }
}


resource "aws_subnet" "mohamad-subnet" {
  vpc_id            = aws_vpc.fursa.id
  cidr_block        = var.subnets[1]  # Class C: 255.255.255.0 
  availability_zone = "eu-central-1a" # Availability Zone 
  tags = {
    Name = "fursa-subnet"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.fursa-subnet.id
  route_table_id = aws_route_table.fursa-route-table.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.fursa.id

  ingress {
    description = "HTTPS"
    from_port   = 443  # 443
    to_port     = 443
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
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "docker"
    from_port   = 5000
    to_port     = 5000
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
    Name = "allow_web"
  }
}
# # 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface1" "web-server-nic" {
  subnet_id       = aws_subnet.fursa-subnet.id
  private_ips     = ["10.30.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}



# # 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.10.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami               = var.image_id[1]     
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "mohamad-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    Name = "web-server"
  }
  
  resource "aws_instance" "web-server-instance2" {
  ami               = var.image_id[2]     
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "mohamad-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    Name = "web-server2"
  }
}

  
  # copy file from my os to the Ubuntu server
  provisioner "file" {
    source      = "C:\\mohamad\\learn\\forsa\\friends\\terraform\\mohamad-terraform\\flask" #the file we need to copy
    destination = "/home/ubuntu" # where we want him to be

    # make connection to the Ubuntu server
    connection {
    type     = "ssh"
    private_key = "${file("C:\\mohamad\\learn\\forsa\\friends\\terraform\\mohamad-terraform\\mohamad-key.pem")}" # RSA private key
    user     = "ubuntu"
    host     = aws_instance.web-server-instance.public_ip #public ip to the Ubuntu server
    agent = false
    }
  }

  # commands to run after creating the Ubuntu server
  provisioner "remote-exec" {
    # commands to build the python image and run it
    inline = [
      "cd flask", 
      "sudo apt update -y",
      "sudo apt install docker.io -y",
      "sudo docker build -t weahther .",
      "sudo docker run -d -p 5000:5000 weather"
    ]

    # make connection to the Ubuntu server
    connection {
    type     = "ssh"
    private_key = "${file("C:\\mohamad\\learn\\forsa\\friends\\terraform\\mohamad-terraform\\mohamad-key.pem")}"  # RSA private key
    user     = "ubuntu"
    host     = aws_instance.web-server-instance.public_ip #public ip to the Ubuntu server
    agent = false
    }
  }
}


# # Create a new load balancer
resource "aws_lb" "fursalb" {
  name               = "fursa"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = ["10.30.1.0/24", "10.30.10.0/24"]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# creat a aws target group
resource "aws_lb_target_group" "targetfursa" {
  name     = "target"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.test.id
}

# connect the old balncer to the target group 
resource "aws_lb_target_group_attachment" "connection" {
  target_group_arn = aws_lb_target_group.targetfursa.arn
  target_id        = aws_instance.web-server-instance.id
  port             = 5000
}



 
