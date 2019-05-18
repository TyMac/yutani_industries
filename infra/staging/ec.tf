resource "aws_instance" "yutani_home" {
    ami = "${var.yutani_home}"
    instance_type = "t2.nano"
    key_name = "${var.aws_key_name}"
    iam_instance_profile = "dna_inst_mgmt"
    vpc_security_group_ids = [
        "${aws_security_group.yutani_webserver_consul_connect.id}",
        "${aws_security_group.yutani_network_web.id}",
        "${aws_security_group.yutani_consul.id}",
        "${aws_security_group.yutani_ssh.id}"
    ]
    
    subnet_id = "${aws_subnet.public_1_subnet_us_east_1c.id}"
    associate_public_ip_address = true
    tags {
        Name = "yutani_fe_homepage-${count.index}"
    }
    
    root_block_device {
        volume_size = "30"
        delete_on_termination = "true"
    }

    count = "2"
    
    connection {
        type = "ssh"
        user = "chef"
        private_key = "${file("${var.aws_key_path}")}"
        timeout = "2m"
        agent = false
    }

    provisioner "chef" {
        attributes_json = <<-EOF
                {
                    "consul": {
                            "servers": ["consul-0.yutani.it", "consul-1.yutani.it", "consul-2.yutani.it"]
                      }
                }
                EOF
        use_policyfile = true
        policy_name = "yutani_page"
        policy_group = "aws_stage_enc"
        node_name       = "yutani_home"
        server_url      = "${var.chef_server_url}"
        recreate_client = true
        skip_install = true
        user_name       = "${var.chef_username}"
        user_key        = "${file("${var.chef_user_key}")}"
        version         = "14"
    }
}

resource "aws_instance" "nginx_lb" {
    ami = "${var.nginx_lb}"
    instance_type = "t2.nano"
    key_name = "${var.aws_key_name}"
    iam_instance_profile = "dna_inst_mgmt"
    vpc_security_group_ids = [
        "${aws_security_group.yutani_webserver_consul_connect.id}",
        "${aws_security_group.yutani_network_lb.id}",
        "${aws_security_group.yutani_consul.id}",
        "${aws_security_group.yutani_ssh.id}"
    ]
    
    subnet_id = "${aws_subnet.public_1_subnet_us_east_1c.id}"
    associate_public_ip_address = true
    tags {
        Name = "yutani_fe_loadbalancer-${count.index}"
    }
    
    root_block_device {
        volume_size = "30"
        delete_on_termination = "true"
    }
    
    count = "2"
    
    connection {
        type = "ssh"
        user = "chef"
        private_key = "${file("${var.aws_key_path}")}"
        timeout = "2m"
        agent = false
    }

    provisioner "chef" {
        attributes_json = <<-EOF
                {
                    "consul": {
                            "servers": ["consul-0.yutani.it", "consul-1.yutani.it", "consul-2.yutani.it"]
                      }
                }
                EOF
        use_policyfile = true
        policy_name = "nginx_lb"
        policy_group = "aws_stage_enc"
        node_name       = "nginx_lb"
        server_url      = "${var.chef_server_url}"
        recreate_client = true
        skip_install = true
        user_name       = "${var.chef_username}"
        user_key        = "${file("${var.chef_user_key}")}"
        version         = "14"
    }
}

# resource "random_id" "consul_server" {
#   keepers = {
#     # Generate a new id each time we switch to a new AMI id
#     ami_id = "${var.consul_server}"
#   }

#   byte_length = 8
# }

resource "aws_instance" "consul_server" {
    ami = "${var.consul_server}"
    instance_type = "t2.nano"
    key_name = "${var.aws_key_name}"
    iam_instance_profile = "dna_inst_mgmt"
    vpc_security_group_ids = [
        "${aws_security_group.yutani_consul.id}",
        "${aws_security_group.yutani_ssh.id}"
    ]
    
    subnet_id = "${aws_subnet.public_1_subnet_us_east_1c.id}"
    associate_public_ip_address = true
  tags = {
    Name = "consul_server-${count.index}"
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
    }

    count = "3"

    provisioner "chef" {
        attributes_json = <<-EOF
                {
                    "consul": {
                            "servers": ["consul-0.yutani.it", "consul-1.yutani.it", "consul-2.yutani.it"]
                      }
                }
                EOF
        use_policyfile = true
        policy_name = "consul_server"
        policy_group = "aws_stage_enc"
        node_name       = "consul_server-${count.index}"
        server_url      = "${var.chef_server_url}"
        recreate_client = true
        skip_install = true
        user_name       = "${var.chef_username}"
        user_key        = "${file("${var.chef_user_key}")}"
        version         = "14"
    }
}

resource "aws_route53_zone" "yutani" {
    name = "yutani.industries"
    delegation_set_id = "${var.aws_delegation_id}"
    
}

resource "aws_route53_zone" "private" {
  name = "yutani.it"

  vpc {
    vpc_id = "${aws_vpc.yutani_network.id}"
  }
}

# resource "aws_route53_zone_association" "yutnai_engineering" {
#   zone_id = ""
#   vpc_id  = "${aws_vpc.yutani_network.id}"
# }

resource "aws_route53_record" "consul_server" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name = "consul-${count.index}"
  type = "A"
  ttl = "3600"
  count = "2"
  records = ["${(aws_instance.consul_server.*.private_ip[count.index])}"]
}
