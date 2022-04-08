/* locals {
  pr_build_check_notifications = toset(flatten([
    for a, b in var.branches : values({
      for k, v in var.services : k => "${b}-${v.name}"
    })
  ]))
} */

resource "aws_sns_topic" "codecheck" {
  for_each                    = toset(var.branches)
  content_based_deduplication = false
  display_name                = "${var.name}-${each.value}"
  fifo_topic                  = false
  name                        = "${var.name}-${each.value}"
  tags                        = var.tags
}

