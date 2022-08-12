variable "enabled" {
  default       = true
  description   = "If set to true, infra will be created and if false, destroyed or not created at all"
}

variable "aws_region" {
  type          = string
  description   = "Primary AWS region for deployment"
}

variable "aws_replica_region" {
  type          = string
  description   = "If needed, region targetted for replication"
}

variable "aws_region_code" {
  type          = string
  description   = "Shortened code for region (e.g. 'use1' for 'us-east-1')"
}

variable "aws_replica_region_code" {
  type          = string
  description   = "Shortened code for replica region (e.g. 'usw2' for 'us-west-2')"
}

variable "aws_team" {
  type          = string
  description   = "Team who will leverage the infra (could be different than infra owner)"
}

variable "tag_automation" {
  type          = string
  description   = "Tag applied to infra to indicate it's been created via pipeline"
}

variable "tag_env" {
  type          = string
  description   = "Environment for deployment (DEV, SQA, UAT, or PRD)"
}

variable "tag_framework" {
  type          = string
  description   = "Terraform (obviously) but used to mark infra deployed this way"
}

variable "tag_owner" {
  type          = string
  description   = "Team responsible for the infrastructure"
}

variable "tag_prefix" {
  type          = string
  description   = "Client prefix (e.g. 'RT' for Raintree)"
}

variable "tag_support_group" {
  type          = string
  description   = "Primary Support Group (generally IT)"
}