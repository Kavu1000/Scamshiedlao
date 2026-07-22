import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../config/app_constants.dart';
import '../../services/overlay_service.dart';

class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    // Listen for events from the main app thread
    OverlayService.broadcastStream.listen((data) {
      if (data is Map && data.containsKey('status')) {
        setState(() {
          _scanning = data['status'] == 'scanning';
        });
      }
    });
  }

  void _onBubbleTap() {
    if (_scanning) return;
    // Notify the main thread that the user clicked to trigger a scan
    FlutterOverlayWindow.shareData({'action': 'trigger_scan'});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: _onBubbleTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBrandSecondary, kBrandPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kBrandSecondary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Center(
              child: _scanning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '🛡',
                      style: TextStyle(fontSize: 26),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
