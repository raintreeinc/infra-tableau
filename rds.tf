resource "aws_db_subnet_group" "this" {
  count                     = var.enabled ? 1 : 0
  name                      = "dbsubnet-${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  subnet_ids                = data.aws_subnets.data-subnets-private.ids
  tags = {
    Name                    = "dbsubnet-${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  }
}

resource "aws_rds_cluster" "this" {
  count                     = var.enabled ? 1 : 0
  db_subnet_group_name      = aws_db_subnet_group.this[count.index].name
  cluster_identifier        = "aurora-${lower(var.aws_region_code)}-${lower(var.tag_env)}-${lower(var.aws_team)}-tableau"
  engine                    = "aurora-postgresql"
  engine_version            = "13.7"
  engine_mode               = "provisioned"
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.this.arn
  database_name             = "db${lower(var.aws_region_code)}${lower(var.tag_env)}${lower(var.aws_team)}tableau"
  master_username           = var.tableau_username
  master_password           = var.tableau_password
  backup_retention_period   = 5
  preferred_backup_window   = "19:00-21:00"
  vpc_security_group_ids    = [data.aws_security_group.inbound-data-management.id, data.aws_security_group.outbound-data.id, data.aws_security_group.inbound-data-db.id]
  skip_final_snapshot       = true
  serverlessv2_scaling_configuration {
    max_capacity            = 64.0
    min_capacity            = 0.5
  }
}

resource "aws_rds_cluster_instance" "this" {
  count                     = var.enabled ? 1 : 0
  cluster_identifier        = aws_rds_cluster.this[count.index].id
  instance_class            = "db.serverless"
  engine                    = aws_rds_cluster.this[count.index].engine
  engine_version            = aws_rds_cluster.this[count.index].engine_version
}