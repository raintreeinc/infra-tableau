resource "aws_secretsmanager_secret" "this" {
  count                   = var.enabled ? 1 : 0
  name                    = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  description             = "${var.aws_team} Tableau Secrets"
  kms_key_id              = data.aws_kms_key.this.id
  replica {
    region                = var.aws_replica_region
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count                   = var.enabled ? 1 : 0
  secret_id               = aws_secretsmanager_secret.this[count.index].id
  secret_string           = jsonencode(tomap({"Tableau Server administrator username" = var.tableau_username, "Tableau Server administrator password" = var.tableau_password, "Tableau Services Manager (TSM) administrator username" = var.tsm_username, "Tableau Services Manager (TSM) administrator password" = var.tsm_password}))
}