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
      // Compact square window (~84dp at 2.6x density) sized to the bubble so
      // the rest of the screen stays tappable. The window is grown later when
      // the result card is shown (see main.dart resizeOverlay).
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "ScamShield Lao",
        overlayContent: "Protection Active",
        height: 220,
        width: 220,
      );
    }
  }

  Future<void> closeAll() => FlutterOverlayWindow.closeOverlay();
}
