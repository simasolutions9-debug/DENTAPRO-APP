---
name: Appointment dashboard figures
description: Product rule for clinic dashboard appointment totals and revenue.
---

For testing and demonstration, the dentist dashboard's daily income is projected from the tariffs configured for scheduled, non-cancelled appointments. It is not collected revenue. A slot without a configured tariff must remain explicitly unpriced rather than being treated as a zero-cost appointment. When Stripe is integrated on the VPS, switch the dashboard to sum only payments with confirmed status.

**Why:** the user explicitly chose appointment-based estimates for testing/demo and said actual dashboard revenue should use confirmed Stripe payments after the VPS integration.

**How to apply:** until Stripe is connected, keep revenue labels clear that they are estimates and leave missing tariffs distinguishable from free appointments. After Stripe integration on the VPS, count only confirmed payment records, not scheduled appointments.
