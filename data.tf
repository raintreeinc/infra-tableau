data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "ec2-instance" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2-access" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:StopInstances"
    ]
    resources = ["*"]
    condition {
      test      = "StringEquals"
      variable  = "aws:ARN"
      values    = ["$${ec2:SourceInstanceARN}"]
    }
  }
}

data "aws_iam_policy_document" "secrets-lookup" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kms-decrypt" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "alb-access" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = ["*"]
  }
}

data "aws_route53_zone" "this" {
  name          = "${lower(var.tag_env)}.raintreeinc.com"
  private_zone  = false
}

data "aws_acm_certificate" "this" {
  domain        = "*.${lower(var.tag_env)}.raintreeinc.com"
  statuses      = ["ISSUED"]
}

data "aws_security_group" "inbound-linux-app-management" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-management-linux"
}

data "aws_security_group" "inbound-linux-devops" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-app-devops-inbound"
}

data "aws_security_group" "inbound-web-public" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-web-public-inbound"
}

data "aws_security_group" "outbound-linux-app" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-app-public-outbound"
}

data "aws_security_group" "inbound-app-efs" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-efs"
}

data "aws_security_group" "inbound-data-management" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-db-management"
}

data "aws_security_group" "outbound-data" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-db-outbound"
}

data "aws_security_group" "inbound-data-db" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-db"
}

data "aws_security_group" "inbound-app-tableau" {
  name          = "${lower(var.aws_region_code)}-sg-${lower(var.tag_env)}-tableau"
}

data "aws_vpc" "this" {
  tags = {
    Purpose     = "Application"
  }
}

data "aws_vpc" "db" {
  tags = {
    Purpose     = "Data"
  }
}

data "aws_subnets" "app-subnets-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Tier = "Public"
  }
}

data "aws_subnets" "app-subnets-private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_subnets" "data-subnets-private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.db.id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_ami" "redhat" {
  owners           = ["309956199498"]
  most_recent      = true
  filter {
    name   = "name"
    values = ["RHEL-8.6.0_HVM-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
