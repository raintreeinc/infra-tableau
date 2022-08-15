resource "aws_iam_role" "ec2-instance" {
  count               = var.enabled ? 1 : 0
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name                = "rt-ec2-tableau"
  path                = "/system/"
  assume_role_policy  = data.aws_iam_policy_document.ec2-instance.json
  inline_policy {
    name   = "policy-ec2-tagging"
    policy = data.aws_iam_policy_document.ec2-access.json
  }
  inline_policy {
    name   = "policy-secrets-lookup"
    policy = data.aws_iam_policy_document.secrets-lookup.json
  }
  inline_policy {
    name   = "policy-kms-decrypt"
    policy = data.aws_iam_policy_document.kms-decrypt.json
  }
  inline_policy {
    name   = "policy-alb-access"
    policy = data.aws_iam_policy_document.alb-access.json
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy",
  ]
  tags = {
    Name = "rt-ec2-tableau"
  }
}
