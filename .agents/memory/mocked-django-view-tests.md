---
name: Mocked Django view tests
description: How to keep auth-view unit tests independent of PostgreSQL in this workspace.
---

The mocked patient-registration view tests use `unittest.TestCase` and `APIRequestFactory` rather than `django.test.SimpleTestCase`. The test bodies passed under `SimpleTestCase`, but Django's test runner raised an `AttributeError` during `tearDownClass`; the standard test base ran cleanly.

**Why:** production registration must be tested without requiring a live PostgreSQL database, and a passing body with a failing suite teardown is not a valid check.

**How to apply:** keep unit tests for mocked auth-view behavior database-free, and retain the ordinary `unittest.TestCase` base unless the teardown issue is independently resolved.
