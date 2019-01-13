provider "aws" {
  region     = "${var.AWS_DEFAULT_REGION}"
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
}

# Apprently remote state needs a statefile.tf made:
# see: https://github.com/hashicorp/terraform/issues/13435
/*
data "terraform_remote_state" "staging" {
  backend = "s3"
  config {
    region = "${var.tfstate_region}"
    bucket = "${var.tfstate_bucket}"
    key = "${var.tfstate_key}"
    encrypt = "true"
  }
}
*/
