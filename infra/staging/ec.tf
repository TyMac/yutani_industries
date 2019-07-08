resource "random_id" "home-id" {
  keepers = {
    # Generate a new id each time we change the yutani home server count
    instance_id = "${var.nginx-web_count}"
  }

  byte_length = 8
}

resource "aws_instance" "nginx-web" {
    ami = var.nginx-web
    instance_type = "t2.nano"
    key_name = var.aws_key_name
    iam_instance_profile = var.iam_instance_profile
    vpc_security_group_ids = [
        "${aws_security_group.yutani_webserver_consul_connect.id}",
        "${aws_security_group.yutani_network_web.id}",
        "${aws_security_group.yutani_consul.id}",
        "${aws_security_group.yutani_ssh.id}"
    ]
    
    subnet_id = "${aws_subnet.public_1_subnet_us_east_1c.id}"
    associate_public_ip_address = true
    tags = {
        Name = "nginx-web-${var.blue_green_side}-${count.index}-${random_id.home-id.hex}"
        ssm_managed = true
        terraform_managed = true
        chef_managed = true
        policy_name = "${var.nginx-web_policy_name}"
        policy_group = "${var.policy_group}"
        consul_managed = true
        blue_green_side = var.blue_green_side
        ami = var.nginx-web
        Platform = "Linux"
        Purpose = "Home Page Web Server"
    }
    
    root_block_device {
        volume_size = "30"
        delete_on_termination = "true"
    }

    count = var.nginx-web_count
    
    connection {
        type = "ssh"
        user = "chef"
        private_key = "${file("${var.aws_key_path}")}"
        timeout = "2m"
        agent = false
        host = self.public_ip
    }

    provisioner "chef" {
        attributes_json = <<-EOF
                {
                    "consul": {
                            "servers": ["provider=aws tag_key=consul_managed tag_value=true"]
                      }
                }
                EOF
        use_policyfile = true
        policy_name = "${var.nginx-web_policy_name}"
        policy_group = "${var.policy_group}"
        node_name       = "nginx-web-${var.blue_green_side}-${count.index}-${random_id.home-id.hex}"
        server_url      = var.chef_server_url
        recreate_client = true
        skip_install = true
        user_name       = var.chef_username
        user_key        = "${file("${var.chef_user_key}")}"
        version         = "14"
    }
}

resource "random_id" "lb-id" {
  keepers = {
    # Generate a new id each time we change the nginx lb server count
    instance_id = "${var.nginx-lb_count}"
  }

  byte_length = 8
}

resource "aws_instance" "nginx-lb" {
    ami = var.nginx-lb
    instance_type = "t2.nano"
    key_name = var.aws_key_name
    iam_instance_profile = var.iam_instance_profile
    vpc_security_group_ids = [
        "${aws_security_group.yutani_webserver_consul_connect.id}",
        "${aws_security_group.yutani_network_lb.id}",
        "${aws_security_group.yutani_consul.id}",
        "${aws_security_group.yutani_ssh.id}"
    ]
    
    subnet_id = "${aws_subnet.public_1_subnet_us_east_1c.id}"
    associate_public_ip_address = true
    tags = {
        Name = "nginx-lb-${var.blue_green_side}-${count.index}-${random_id.lb-id.hex}"
        ssm_managed = true
        terraform_managed = true
        chef_managed = true
        policy_name = "${var.nginx-lb_policy_name}"
        policy_group = "${var.policy_group}"
        consul_managed = true
        blue_green_side = var.blue_green_side
        ami = var.nginx-lb
        Platform = "Linux"
        Purpose = "FE Load Balancer"
    }
    
    root_block_device {
        volume_size = "30"
        delete_on_termination = "true"
    }
    
    count = var.nginx-lb_count
    
    connection {
        type = "ssh"
        user = "chef"
        private_key = "${file("${var.aws_key_path}")}"
        timeout = "2m"
        agent = false
        host = self.public_ip
    }

    provisioner "chef" {
        attributes_json = <<-EOF
                {
                    "consul": {
                            "servers": ["provider=aws tag_key=consul_managed tag_value=true"]
                      }
                }
                EOF
        use_policyfile = true
        policy_name = "${var.nginx-lb_policy_name}"
        policy_group = "${var.policy_group}"
        node_name       = "nginx-lb-${var.blue_green_side}-${count.index}-${random_id.lb-id.hex}"
        server_url      = var.chef_server_url
        recreate_client = true
        skip_install = true
        user_name       = var.chef_username
        user_key        = "${file("${var.chef_user_key}")}"
        version         = "14"
    }
}

resource "random_id" "consul-id" {
  keepers = {
    # Generate a new id each time we change the consul server count
    instance_id = "${var.consul-server_count}"
  }

  byte_length = 8
}

resource "aws_instance" "consul-server" {
    ami = var.consul-server
    instance_type = "t2.nano"
    key_name = var.aws_key_name
    iam_instance_profile = var.iam_instance_profile
    vpc_security_group_ids = [
        "${aws_security_group.yutani_consul.id}",
        "${aws_security_group.yutani_ssh.id}"
    ]
    
    subnet_id = "${aws_subnet.public_1_subnet_us_east_1c.id}"
    associate_public_ip_address = true
  tags = {
    Name = "consul-server-${var.blue_green_side}-${count.index}-${random_id.consul-id.hex}"
    ssm_managed = true
    terraform_managed = true
    chef_managed = true
    policy_name = "${var.consul-server_policy_name}"
    policy_group = "${var.policy_group}"
    consul_managed = true
    blue_green_side = var.blue_green_side
    ami = var.consul-server
    Platform = "Linux"
    Purpose = "Consul Server"
  }
    
    root_block_device {
        volume_size = "30"
        delete_on_termination = "true"
    }
    
    connection {
        type = "ssh"
        user = "chef"
        private_key = "${file("${var.aws_key_path}")}"
        timeout = "2m"
        agent = false
        host = self.public_ip
    }

    count = var.consul-server_count

    provisioner "chef" {
        attributes_json = <<-EOF
                {
                    "consul": {
                            "count": "${var.consul-server_count}",
                            "servers": ["provider=aws tag_key=consul_managed tag_value=true"]
                      }
                }
                EOF
        use_policyfile = true
        policy_name = "${var.consul-server_policy_name}"
        policy_group = "${var.policy_group}"
        node_name       = "consul-server-${var.blue_green_side}-${count.index}-${random_id.consul-id.hex}"
        server_url      = var.chef_server_url
        recreate_client = true
        skip_install = true
        user_name       = var.chef_username
        user_key        = "${file("${var.chef_user_key}")}"
        version         = "14"
    }
}

resource "aws_route53_zone" "yutani" {
    name = "yutani.industries"
    delegation_set_id = var.aws_delegation_id
}

resource "aws_route53_zone" "private" {
  name = "yutani.it"

  vpc {
    vpc_id = "${aws_vpc.yutani_network.id}"
  }
}

# resource "aws_route53_zone_association" "private" {
#   zone_id = "${aws_route53_zone.private.zone_id}"
#   vpc_id  = "${aws_vpc.yutani_network.id}"
# }

resource "aws_route53_record" "nginx-web" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name = "nginx-web-${var.blue_green_side}-${count.index}-${random_id.home-id.hex}"
  type = "A"
  ttl = "3600"
  count = var.nginx-web_count
  records = [aws_instance.nginx-web[count.index].private_ip]
}

resource "aws_route53_record" "nginx-lb" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name = "nginx-lb-${var.blue_green_side}-${count.index}-${random_id.lb-id.hex}"
  type = "A"
  ttl = "3600"
  count = var.nginx-lb_count
  records = [aws_instance.nginx-lb[count.index].private_ip]
}

resource "aws_route53_record" "consul-server" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name = "consul-server-${var.blue_green_side}-${count.index}-${random_id.consul-id.hex}"
  type = "A"
  ttl = "3600"
  count = var.consul-server_count
  records = [aws_instance.consul-server[count.index].private_ip]
}
