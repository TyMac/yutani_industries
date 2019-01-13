### AWS Cert Manager Cert Block ###
resource "aws_acm_certificate" "yutani_cert" {
  domain_name = "yutani.industries"
  validation_method = "DNS"
}

resource "aws_route53_record" "yutani_validation" {
  name = "${aws_acm_certificate.yutani_cert.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.yutani_cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.yutani.zone_id}"
  records = ["${aws_acm_certificate.yutani_cert.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "yutani_cert" {
  certificate_arn = "${aws_acm_certificate.yutani_cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.yutani_validation.fqdn}"]
}

### Self Signed Cert Block ###
/*
resource "tls_private_key" "yutani" {
  algorithm = "RSA"
}
*/

/*
resource "tls_self_signed_cert" "yutani" {
  key_algorithm   = "${tls_private_key.yutani.algorithm}"
  private_key_pem = "${tls_private_key.yutani.private_key_pem}"

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
      "key_encipherment",
      "digital_signature",
      "server_auth",
  ]

  dns_names = ["yutani.industries", "www.yutani.industries"]

  subject {
      common_name  = "yutani.industries"
      organization = "Yutani Corporation, Yutani Industries, Ltd"
  }
}

# For yutani, this can be used to populate an AWS IAM server certificate.
resource "aws_iam_server_certificate" "yutani" {
  name             = "yutani_self_signed_cert"
  certificate_body = "${tls_self_signed_cert.yutani.cert_pem}"
  private_key      = "${tls_private_key.yutani.private_key_pem}"

    lifecycle {
    create_before_destroy = true
  }
}
*/

### ACME Cert Block ###
/*
# Set up a registration using a private key from tls_private_key
resource "acme_registration" "reg" {
  server_url      = "https://acme-staging.api.letsencrypt.org/directory"
  account_key_pem = "${tls_private_key.yutani.private_key_pem}"
  email_address   = "yutani@nym.hush.com"
}

# Create a certificate
resource "acme_certificate" "yutani_cert" {
  server_url                = "https://acme-staging.api.letsencrypt.org/directory"
  account_key_pem           = "${tls_private_key.yutani.private_key_pem}"
  common_name               = "yutani.industries"
  subject_alternative_names = ["www.yutani.industries"]

  dns_challenge {
    provider = "route53"
  }

  registration_url = "${acme_registration.reg.id}"
}
*/