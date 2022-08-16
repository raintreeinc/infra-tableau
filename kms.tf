resource "aws_kms_key" "this" {
  description             = "${var.aws_team} Tableau KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Enable IAM User Permissions",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "logs.${var.aws_region}.amazonaws.com"
        },
        "Action": [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        "Resource": "*",
        "Condition": {
        "ArnEquals": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.this.account_id}:log-group:${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
        }
      }
    }
  ]
}
EOF
  tags = {
    Name = "${lower(var.aws_region_code)}-kms-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${lower(var.aws_region_code)}-kms-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  target_key_id = aws_kms_key.this.key_id
}