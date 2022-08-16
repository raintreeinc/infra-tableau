resource "aws_efs_file_system" "this" {
  count                                 = var.enabled ? 1 : 0
  creation_token                        = "efs-${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  encrypted                             = true
  kms_key_id                            = data.aws_kms_key.this.arn
  lifecycle_policy {
    transition_to_ia                    = "AFTER_7_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_access_point" "this" {
  count                                 = var.enabled ? 1 : 0
  file_system_id                        = aws_efs_file_system.this[count.index].id
}

resource "aws_efs_mount_target" "this" {
  for_each                              = toset(data.aws_subnets.app-subnets-private.ids)
  file_system_id                        = aws_efs_file_system.this[0].id
  subnet_id                             = each.key
}
