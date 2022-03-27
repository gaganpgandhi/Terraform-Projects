resource "aws_vpc" "homevpc" {
    cidr_block = "172.12.0.0/16"
    tags = {
      "Name" = "Home VPC"
    }
  
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.homevpc.id
  tags = {
    "Name" = "Home Vpc Internet Gateway"
  }
}

resource "aws_route_table" "homevpcrt" {
  vpc_id = aws_vpc.homevpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Home VPC Route Table"
  }
}


resource "aws_subnet" "subnet-1" {
  
  vpc_id     = aws_vpc.homevpc.id
  cidr_block = "172.12.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "prod subnet 1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.homevpcrt.id
}


resource "aws_security_group" "websc" {
  name        = "websc"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.homevpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["172.12.1.0/24"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["172.12.1.0/24"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["172.12.1.0/24"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}



resource "aws_network_interface" "homevpcnetint" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["172.12.1.50"]
  security_groups = [aws_security_group.websc.id]

/*   attachment {
    instance = aws_instance.web.id
    device_index=1
  } */

}

resource "aws_eip" "homevpceip" {
  vpc = true
  associate_with_private_ip = "172.12.1.50"
  network_interface = aws_network_interface.homevpcnetint.id
  
  depends_on = [aws_internet_gateway.gw]
  

}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.homevpceip.id
}

resource "aws_instance" "web" {
  ami               = "ami-060c4f2d72966500a"
  availability_zone = "eu-west-2a"
  instance_type     = "t2.micro"
  key_name = "terraform"

  network_interface {
    device_index = "0"
    network_interface_id = aws_network_interface.homevpcnetint.id 
  }

  tags = {
    Name = "HelloWorld"
  }

  user_data = <<-EOF
            sudo apt update -y
            sudo apt get apache2 -y
            bash -c echo "This is my first html  page hosted on aws via terraform" > /var/www/html/index.html
            sudo apt get systemctl start apache2
            EOF
}














