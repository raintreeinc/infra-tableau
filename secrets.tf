resource "aws_secretsmanager_secret" "this" {
  count                   = var.enabled ? 1 : 0
  name                    = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  description             = "${var.aws_team} Tableau Secrets"
  kms_key_id              = aws_kms_key.this.id
  replica {
    region                = var.aws_replica_region
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count                   = var.enabled ? 1 : 0
  secret_id               = aws_secretsmanager_secret.this[count.index].id
  secret_string           = jsonencode(tomap({"server_admin" = var.tableau_username, "server_admin_pw" = var.tableau_password, "tsm_admin" = var.tsm_username, "tsm_admin_password" = var.tsm_password, "core_key" = var.tableau_license, "efs_id" = aws_efs_file_system.this[count.index].id}))
}