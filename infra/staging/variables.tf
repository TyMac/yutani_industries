variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_DEFAULT_REGION" {}
variable "aws_key_name" {}
variable "aws_key_path" {}
variable "aws_region" {}
variable "nginx-web" {}
variable "nginx-lb" {}
variable "infra-server" {}
variable "aws_delegation_id" {}
variable "chef_server_url" {}
variable "bastion_ip" {}
variable "chef_user_key" {}
variable "chef_username" {}
variable "tfstate_key" {}
variable "tfstate_bucket" {}
variable "tfstate_region" {}

variable "nginx-web_count" {}

variable "nginx-lb_count" {}

variable "infra-server_count" {}

variable blue_green_side {}

variable policy_group {}

variable nginx-web_policy_name {}

variable nginx-lb_policy_name {}

variable infra-server_policy_name {}

variable iam_instance_profile {}
