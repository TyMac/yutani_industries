/* Define our vpc */
resource "aws_vpc" "yutani_network" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name"                  = "Terraform_VPC"
    "Terraform_Managed"     = "True"
  }
}

resource "aws_subnet" "public_1_subnet_us_east_1c" {
  vpc_id            = "${aws_vpc.yutani_network.id}"
  cidr_block        = "172.31.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name"                  = "Subnet public 1 az 1c"
    "Terraform_Managed"     = "True"
  }
}

resource "aws_subnet" "public_2_subnet_us_east_1d" {
  vpc_id            = "${aws_vpc.yutani_network.id}"
  cidr_block        = "172.31.3.0/24"
  availability_zone = "us-east-1d"

  tags = {
    "Name"                  = "Subnet public 2 az 1d"
    "Terraform_Managed"     = "True"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.yutani_network.id}"

  tags {
    "Name"                  = "InternetGateway"
    "Terraform_Managed"     = "True"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.yutani_network.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.public_1_subnet_us_east_1c.id}"
  route_table_id = "${aws_vpc.yutani_network.main_route_table_id}"
}

resource "aws_route_table_association" "b" {
  subnet_id      = "${aws_subnet.public_2_subnet_us_east_1d.id}"
  route_table_id = "${aws_vpc.yutani_network.main_route_table_id}"
}

resource "aws_security_group" "yutani_network_web" {
  name        = "yutani_web"
  description = "allows http traffic"
  vpc_id      = "${aws_vpc.yutani_network.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_ip}/32", "172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Terraform_Managed" = "True"
    "Name"              = "Web_SG"
    "Purpose"           = "Web_Communication"
  }
}

resource "aws_security_group" "yutani_network_lb" {
  name        = "yutani_lb"
  description = "allows http traffic"
  vpc_id      = "${aws_vpc.yutani_network.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_ip}/32", "172.31.2.0/24", "172.31.3.0/24"]
  }

  # Change bastion_ip to 0.0.0.0/0 in production
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_ip}/32", "172.31.2.0/24", "172.31.3.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Terraform_Managed" = "True"
    "Name"              = "Load_balancer_SG"
    "Purpose"           = "LB_Communication"
  }
}

resource "aws_security_group" "yutani_consul" {
  name        = "yutani_consul_sever"
  description = "allows consul service discovery traffic"
  vpc_id      = "${aws_vpc.yutani_network.id}"

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_ip}/32", "172.31.2.0/24", "172.31.3.0/24"]
  }

  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_ip}/32", "172.31.2.0/24", "172.31.3.0/24"]
  } 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Terraform_Managed" = "True"
    "Name"              = "Consul_SG"
    "Purpose"           = "Consul_Service_Discovery_Communication"
  }
}

resource "aws_security_group" "yutani_webserver_consul_connect" {
  name        = "yutani_webserver_consul_connect"
  description = "allows consul service yutani_webserver to connect to yutani_loadbalancer"
  vpc_id      = "${aws_vpc.yutani_network.id}"
  ingress {
    from_port   = 9191
    to_port     = 9191
    protocol    = "tcp"
    cidr_blocks = ["172.31.2.0/24", "172.31.3.0/24"]
  }
}

resource "aws_security_group" "yutani_ssh" {
  name        = "ssh_access"
  description = "allows ssh traffic"
  vpc_id      = "${aws_vpc.yutani_network.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_ip}/32", "172.31.2.0/24", "172.31.3.0/24"]
  }
}
