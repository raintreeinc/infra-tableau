resource "aws_route53_record" "tableau" {
  count                     = var.enabled ? 1 : 0
  zone_id                   = aws_route53_zone.this.zone_id
  name                      = "tableau.${lower(var.tag_env)}.raintreeinc.com"
  type                      = "A"
  alias {
    name                    = aws_lb.tableau[count.index].dns_name
    zone_id                 = aws_lb.tableau[count.index].zone_id
    evaluate_target_health  = true
  }
}

resource "aws_route53_record" "tsm" {
  count                     = var.enabled ? 1 : 0
  zone_id                   = aws_route53_zone.this.zone_id
  name                      = "tableau-tsm.${lower(var.tag_env)}.raintreeinc.com"
  type                      = "A"
  alias {
    name                    = aws_lb.tsm[count.index].dns_name
    zone_id                 = aws_lb.tsm[count.index].zone_id
    evaluate_target_health  = true
  }
}