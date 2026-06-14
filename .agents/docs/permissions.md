# Permissions

## Android Manifest (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<application android:largeHeap="true" ... />
```

## Runtime Flow

In `main.dart`: `await Permission.microphone.request()` is called on every app start. The OS dialog appears if not yet granted. No custom permission rationale screen exists yet.

## Permission Handler

Using `permission_handler` v11.4.0 package. The `record` package (v6.0.0) also has its own `record.hasPermission()` check, but it isn't called in the current code — the main.dart request is sufficient since both use the same underlying Android permission.
