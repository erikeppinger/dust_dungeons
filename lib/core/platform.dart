import 'package:flutter/foundation.dart';

/// Whether this is the Android app. Screen time and home screen widgets
/// exist only there; the Windows app leaves them out.
bool get isAndroidApp => defaultTargetPlatform == TargetPlatform.android;

/// Whether this is the Windows app.
bool get isWindowsApp => defaultTargetPlatform == TargetPlatform.windows;
