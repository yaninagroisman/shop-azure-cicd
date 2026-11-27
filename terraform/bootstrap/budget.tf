# Subscription-wide monthly budget (AD-35). It lives in the bootstrap, not in
# the main stack, so it keeps watching after `terraform destroy` and catches
# anything left running by mistake.
#
# A budget only sends notifications: it does not stop spending. Cost data
# arrives with an 8-24 hour delay. On the Free Trial the real hard limit is
# the $200 spending limit.

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-${var.project}-monthly"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    # First day of the current month (required by the API). Fixed at creation
    # time, see ignore_changes below.
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", plantimestamp())
  }

  dynamic "notification" {
    for_each = local.budget_notifications

    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = var.budget_contact_emails
    }
  }

  lifecycle {
    # plantimestamp() changes every run; the start date must not.
    ignore_changes = [time_period]
  }
}
