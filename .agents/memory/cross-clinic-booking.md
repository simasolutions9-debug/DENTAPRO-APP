---
name: Cross-clinic booking
description: Product rules for patient bookings across clinic tenants.
---

Patients may reserve at any active clinic in the marketplace, not only the tenant attached to their account. Reservations must use a future slot published by that clinic. The clinic is resolved from its public slug and slot; patient identity must match the authenticated token and patient profile, never an arbitrary client-selected patient.

**Why:** the user chose cross-clinic booking and explicitly rejected invented availability times.

**How to apply:** keep clinic ownership tied to the selected published slot, validate the patient against the login identity, and prevent a slot from being booked more than once.
