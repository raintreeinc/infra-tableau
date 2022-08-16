resource "aws_s3_bucket" "this" {
  count                   = var.enabled ? 1 : 0
  bucket                  = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  tags = {
    Name                  = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
    Environment           = var.tag_env
    Owner                 = var.tag_owner
    SupportGroup          = var.tag_support_group
    Framework             = var.tag_framework
    Automation            = var.tag_automation
  }
  lifecycle {
    ignore_changes = [
      server_side_encryption_configuration
    ]
  }
}

resource "aws_s3_bucket_acl" "this" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.this[count.index].id
  acl                     = "private"
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.this[count.index].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.this[count.index].bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id   = aws_kms_key.this.id
      sse_algorithm       = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.this[count.index].bucket
  versioning_configuration {
    status                = "Enabled"
  }
}

resource "aws_s3_object" "infra-tableau" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.this[count.index].bucket
  acl                     = "private"
  key                     = "logs/infra-tableau/"
  source                  = "/dev/null"
  kms_key_id              = aws_kms_key.this.arn
}

resource "aws_s3_bucket_logging" "this" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.this[count.index].bucket
  target_bucket           = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.tag_owner)}-logs"
  target_prefix           = "logs/infra-tableau/"
}