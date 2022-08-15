resource "aws_cloudwatch_log_group" "this" {
  count                   = var.enabled ? 1 : 0
  name                    = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  kms_key_id              = data.aws_kms_key.this.id
  tags = {
    Name =                "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  }
}