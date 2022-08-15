resource "aws_autoscaling_group" "this" {
  count                 = var.enabled ? 1 : 0
  name                  = "ASG-${upper(var.aws_region_code)}-${upper(var.tag_env)}-${upper(var.aws_team)}-TABLEAU"
  vpc_zone_identifier   = data.aws_subnets.app-subnets-public.ids
  desired_capacity      = 1
  max_size              = 1
  min_size              = 1
  target_group_arns     = [
    aws_lb_target_group.tableau[count.index].arn,
    aws_lb_target_group.tsm[count.index].arn
  ]
  launch_template {
    id                  = aws_launch_template.this[count.index].id
    version             = "$Latest"
  }
  instance_refresh {
    strategy            = "Rolling"
  }
}