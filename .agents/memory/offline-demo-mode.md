---
name: Offline patient persistence
description: Local data and network boundary for patient booking, dashboard, and demo flows.
---

Patient profiles and appointments are persisted locally in Hive. The patient dashboard reads its appointments from the local store, and confirming a booking must save locally without POSTing to the backend. Every route reachable in Demo Mode must remain offline, including bottom tabs, quick actions, clinic catalog, and booking.

**Why:** the user requires the app to support offline demonstrations before the Django VPS is deployed and explicitly specified local appointment persistence instead of an HTTP booking request.

**How to apply:** use the app provider and Hive storage for patient state and bookings; seed demonstration appointments once rather than hardcoding dashboard values; keep the demo entry point disabled in release builds unless the user explicitly approves otherwise.
