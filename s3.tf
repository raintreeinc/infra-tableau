resource "aws_s3_bucket" "this" {
  bucket                = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  tags = {
    Name                = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
    Environment         = var.tag_env
    Owner               = var.tag_owner
    SupportGroup        = var.tag_support_group
    Framework           = var.tag_framework
    Automation          = var.tag_automation
  }
  lifecycle {
    ignore_changes = [
      server_side_encryption_configuration
    ]
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket                = aws_s3_bucket.this.id
  acl                   = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket                = aws_s3_bucket.this.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_key.this.id
      sse_algorithm     = "aws:kms"
    }
  }
}