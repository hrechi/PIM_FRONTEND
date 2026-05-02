import base64, os

# Complete animal_details_screen.dart encoded as base64
# This avoids all shell quoting issues

DART_B64 = (
"aW1wb3J0ICdwYWNrYWdlOmZsdXR0ZXIvbWF0ZXJpYWwuZGFydCc7CmltcG9ydCAncGFja2FnZTpt"
"YXRlcmlhbF9zeW1ib2xzX2ljb25zL3N5bWJvbHMuZGFydCc7CmltcG9ydCAncGFja2FnZTppbnRs"
"L2ludGwuZGFydCc7CmltcG9ydCAnLi4vLi4vbW9kZWxzL2FuaW1hbC5kYXJ0JzsKaW1wb3J0ICcu"
"Li8uLi9zZXJ2aWNlcy9hbmltYWxfc2VydmljZS5kYXJ0JzsKaW1wb3J0ICcuLi8uLi91dGlscy9j"
"b25zdGFudHMuZGFydCc7CmltcG9ydCAnLi4vLi4vdXRpbHMvYW5pbWFsX3V0aWxzLmRhcnQnOwpp"
"bXBvcnQgJ2FkZF9hbmltYWxfc2NyZWVuLmRhcnQnOwppbXBvcnQgJ2FuaW1hbF9maW5hbmNlX3Nj"
"cmVlbi5kYXJ0JzsKaW1wb3J0ICdzZWxsX2FuaW1hbF9zY3JlZW4uZGFydCc7Cg=="
)

content = base64.b64decode(DART_B64).decode('utf-8')
print("Decoded", len(content), "bytes")
print(content[:100])
