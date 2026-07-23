import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final screenCaptureServiceProvider =
    Provider<ScreenCaptureService>((ref) => ScreenCaptureService());

/// Bridges to native Android MediaProjection screen capture (see
/// MainActivity.kt / ScreenCaptureManager.kt). Captures whatever is currently
/// on the physical display — the app the user is actually looking at — not
/// just this app's own UI.
class ScreenCaptureService {
  static const _channel =
      MethodChannel('com.scamshield.scamshield_lao_mobile/screen_capture');

  /// Shows the system screen-capture consent dialog. Must be called once
  /// (while this app is in the foreground) before [capture] can succeed.
  Future<bool> requestPermission() async {
    final granted = await _channel.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  }

  Future<bool> isActive() async {
    final active = await _channel.invokeMethod<bool>('isActive');
    return active ?? false;
  }

  /// Captures a single frame of the current screen and returns the path to
  /// the saved PNG, or null if permission hasn't been granted / capture failed.
  Future<String?> capture() async {
    try {
      return await _channel.invokeMethod<String>('capture');
    } on PlatformException catch (e) {
      debugPrint('[ScamShield] capture PlatformException: ${e.code} ${e.message}');
      return null;
    }
  }

  Future<void> stopProjection() => _channel.invokeMethod('stopProjection');
}
