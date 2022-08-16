resource "aws_rds_cluster" "this" {
  count                   = var.enabled ? 1 : 0
  cluster_identifier      = "aurora-${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  engine                  = "aurora-postgresql"
  engine_version          = "13.7"
  engine_mode             = "serverless"
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.this.arn
  database_name           = "db-${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  master_username         = var.tableau_username
  master_password         = var.tableau_password
  backup_retention_period = 5
  preferred_backup_window = "19:00-21:00"
}
