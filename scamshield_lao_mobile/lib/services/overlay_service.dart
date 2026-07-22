import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final overlayServiceProvider = Provider<OverlayService>((ref) => OverlayService());

class OverlayService {
  /// A broadcast stream wrapper for FlutterOverlayWindow.overlayListener
  /// to prevent "Stream has already been listened to" errors.
  static final Stream<dynamic> broadcastStream =
      FlutterOverlayWindow.overlayListener.asBroadcastStream();

  Future<bool> checkPermission() => FlutterOverlayWindow.isPermissionGranted();

  Future<void> requestPermission() => FlutterOverlayWindow.requestPermission();

  Future<void> showBubble() async {
    if (!await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "ScamShield Lao",
        overlayContent: "Protection Active",
        height: 500,
        width: 400,
      );
    }
  }

  Future<void> closeAll() => FlutterOverlayWindow.closeOverlay();
}
