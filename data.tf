data "aws_kms_key" "this" {
  key_id = "alias/${lower(var.aws_region_code)}-kms-${lower(var.tag_env)}-${lower(var.aws_team)}"
}