resource "aws_secretsmanager_secret" "this" {
  count                   = var.enabled ? 1 : 0
  name                    = "${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  description             = "${var.aws_team} Tableau Secrets"
  kms_key_id              = data.aws_kms_key.this.id
  replica {
    region                = var.aws_replica_region
  }
}