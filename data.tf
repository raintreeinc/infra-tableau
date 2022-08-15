data "aws_kms_key" "this" {
  key_id = "alias/${lower(var.aws_region_code)}-kms-${lower(var.tag_env)}-${lower(var.tag_owner)}"
}

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
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kms-decrypt" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "alb-access" {
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

data "aws_vpc" "this" {
  tags = {
    Purpose     = "Application"
  }
}

data "aws_subnet_ids" "app-subnets-public" {
  vpc_id                  = data.aws_vpc.this.id
  tags = {
    Tier        = "Public"
  }
}

data "aws_subnet_ids" "app-subnets-private" {
  vpc_id                  = data.aws_vpc.this.id
  tags = {
    Tier        = "Private"
  }
}

data "aws_ami" "redhat" {
  owners           = ["309956199498"]
  most_recent      = true
  filter {
    name   = "name"
    values = ["RHEL-8.6.0_HVM-*"]
  }
}