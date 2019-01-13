resource "aws_elb" "yutani_app" {
  
    name                        = "yutani-terraform-deployment"
    cross_zone_load_balancing   = true
    instances                   = ["${aws_instance.nginx_lb.id}"]
    security_groups             = ["${aws_security_group.yutani_network_lb.id}"]
    subnets                     = ["${aws_subnet.private_1_subnet_us_east_1c.id}", "${aws_subnet.private_2_subnet_us_east_1d.id}"]

    listener {
        instance_port      = 443
        instance_protocol  = "https"
        lb_port            = 443
        lb_protocol        = "https"
        # ssl_certificate_id = "${aws_iam_server_certificate.yutani.arn}"
        # ssl_certificate_id = "${acme_certificate.yutani_cert.id}"
        ssl_certificate_id = "${aws_acm_certificate.yutani_cert.id}"
    }
  
    listener {
        instance_port     = 443
        instance_protocol = "https"
        lb_port           = 80
        lb_protocol       = "http"
        # ssl_certificate_id = "${aws_acm_certificate.yutani_cert.id}"
    }

    health_check = [
        {
            target              = "HTTPS:443/"
            interval            = 30
            healthy_threshold   = 2
            unhealthy_threshold = 2
            timeout             = 5
    },
    ]

    tags = {
        Terraform_Managed   = "True"
        Environment         = "Staging"
    }
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.yutani.zone_id}"
  name    = "yutani.industries"
  type    = "A"

  alias {
    name                   = "${aws_elb.yutani_app.dns_name}"
    zone_id                = "${aws_elb.yutani_app.zone_id}"
    evaluate_target_health = true
  }
}
