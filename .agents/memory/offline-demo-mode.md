---
name: Offline demo mode
description: Data boundary for all screens reachable from the temporary patient demo login.
---

Every screen and route reachable in patient Demo Mode must use injected local mock data and must not make HTTP requests to the backend. This includes bottom tabs, quick actions, clinic catalog, and booking.

**Why:** the user explicitly required the APK demo to remain fully usable before the VPS is deployed, without accidental real API calls.

**How to apply:** pass the demo patient, appointments, and local repository fakes through navigation; keep the demo entry point disabled in release builds unless the user explicitly approves otherwise.
