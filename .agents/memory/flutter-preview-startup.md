---
name: Flutter preview startup
description: A startup timing quirk when checking the Flutter web-server preview.
---

In this workspace, the Flutter web-server preview can temporarily return HTML for its JavaScript entrypoint just after restart while Dart compilation is still underway. This can make an immediate screenshot appear blank even though the app is starting normally.

**Why:** a preview captured during compilation returned the wrong MIME type; after the workflow reported that `main.dart` was being served, the page loaded normally.

**How to apply:** after restarting the Flutter web workflow, wait for its ready/serving log before diagnosing a blank screenshot. Investigate code or port forwarding if the response is still incorrect after the server is ready.
