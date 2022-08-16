resource "aws_kms_key" "this" {
  description             = "${var.aws_team} Tableau KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = {
    Name = "${lower(var.aws_region_code)}-kms-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${lower(var.aws_region_code)}-kms-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  target_key_id = aws_kms_key.this.key_id
}