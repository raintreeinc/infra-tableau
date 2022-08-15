resource "aws_lb" "tableau" {
  count                       = var.enabled ? 1 : 0
  #tfsec:ignore:aws-elbv2-alb-not-public
  name                        = "ALB-${upper(var.aws_region_code)}-${upper(var.tag_env)}-${upper(var.aws_team)}-TABLEAU"
  internal                    = false
  load_balancer_type          = "application"
  subnets                     = data.aws_subnets.app-subnets-public.ids
  enable_deletion_protection  = false
  drop_invalid_header_fields  = true
  security_groups             = [data.aws_security_group.inbound-linux-app-management.id, data.aws_security_group.inbound-web-public.id, data.aws_security_group.outbound-linux-app.id]
}

resource "aws_lb" "tsm" {
  count                       = var.enabled ? 1 : 0
  #tfsec:ignore:aws-elbv2-alb-not-public
  name                        = "ALB-${upper(var.aws_region_code)}-${upper(var.tag_env)}-${upper(var.aws_team)}-TSM"
  internal                    = false
  load_balancer_type          = "application"
  subnets                     = data.aws_subnets.app-subnets-public.ids
  enable_deletion_protection  = false
  drop_invalid_header_fields  = true
  security_groups             = [data.aws_security_group.inbound-linux-devops.id, data.aws_security_group.inbound-linux-app-management.id, data.aws_security_group.inbound-web-public.id, data.aws_security_group.outbound-linux-app.id]
}

resource "aws_lb_listener" "tableau-http" {
  count                       = var.enabled ? 1 : 0
  load_balancer_arn           = aws_lb.tableau[count.index].arn
  port                        = "80"
  protocol                    = "HTTP"
  default_action {
    type                      = "redirect"
    redirect {
      host                    = "#{host}"
      path                    = "/#{path}"
      query                   = "#{query}"
      port                    = "443"
      protocol                = "HTTPS"
      status_code             = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "tableau-https" {
  count                       = var.enabled ? 1 : 0
  load_balancer_arn           = aws_lb.tableau[count.index].arn
  port                        = "443"
  protocol                    = "HTTPS"
  ssl_policy                  = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn             = data.aws_acm_certificate.this.arn
  default_action {
    type                      = "forward"
    target_group_arn          = aws_lb_target_group.tableau[count.index].arn
  }
}

resource "aws_lb_listener" "tsm-http" {
  count                       = var.enabled ? 1 : 0
  load_balancer_arn           = aws_lb.tsm[count.index].arn
  port                        = "80"
  protocol                    = "HTTP"
  default_action {
    type                      = "redirect"
    redirect {
      host                    = "#{host}"
      path                    = "/#{path}"
      query                   = "#{query}"
      port                    = "443"
      protocol                = "HTTPS"
      status_code             = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "tsm-https" {
  count                       = var.enabled ? 1 : 0
  load_balancer_arn           = aws_lb.tsm[count.index].arn
  port                        = "443"
  protocol                    = "HTTPS"
  ssl_policy                  = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn             = data.aws_acm_certificate.this.arn
  default_action {
    type                      = "forward"
    target_group_arn          = aws_lb_target_group.tsm[count.index].arn
  }
}