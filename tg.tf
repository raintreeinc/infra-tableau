resource "aws_lb_target_group" "tableau" {
  name                          = "TG-${upper(var.aws_region_code)}-${upper(var.tag_env)}-${upper(var.aws_team)}-TABLEAU"
  port                          = 80
  protocol                      = "HTTPS"
  vpc_id                        = data.aws_vpc.this.id
  load_balancing_algorithm_type = "round_robin"
  deregistration_delay          = 300
  stickiness {
    type                        = "lb_cookie"
    cookie_duration             = 86400
    enabled                     = true
  }
}


resource "aws_lb_target_group" "tsm" {
  name                          = "TG-${upper(var.aws_region_code)}-${upper(var.tag_env)}-${upper(var.aws_team)}-TSM"
  port                          = 8850
  protocol                      = "HTTPS"
  vpc_id                        = data.aws_vpc.this.id
  load_balancing_algorithm_type = "round_robin"
  deregistration_delay          = 300
  stickiness {
    type                        = "lb_cookie"
    cookie_duration             = 86400
    enabled                     = true
  }
}
