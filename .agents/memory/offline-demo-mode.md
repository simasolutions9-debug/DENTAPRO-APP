---
name: Offline patient data and mock RBAC
description: Local patient data boundary and safe scope for temporary role-based mock authentication.
---

Patient profiles and appointments are persisted locally in Hive. The patient dashboard reads appointments from the local store, and confirming a booking saves locally without POSTing to the backend. The former Demo Mode entry point is removed. Temporary email-only role routing is restricted to debug builds by default; release builds use real authentication unless a test build explicitly enables the mock flag.

**Why:** the user requested local patient flows before the Django VPS is deployed and later replaced the Demo login with temporary email-based role routing. A release-default mock would expose privileged dashboards without password checks.

**How to apply:** use AppProvider and Hive for patient profiles and bookings; keep the role mock debug-only by default, and use the explicit `DENTAPRO_MOCK_RBAC` build define only for isolated test artifacts.
