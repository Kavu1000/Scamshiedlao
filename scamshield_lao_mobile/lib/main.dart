import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/app_constants.dart';
import 'screens/overlay/overlay_bubble.dart';
import 'screens/overlay/overlay_result_card.dart';
import 'services/overlay_service.dart';

// Overlay window sizes (dp) — the floating bubble is small so the rest of the
// screen stays tappable; the result card needs a much larger window or it
// overflows. resizeOverlay() switches between them.
const double _kBubbleSize = 84;
const double _kResultWidth = 340;
const double _kResultHeight = 380;

// The overlay engine's own control channel (handled natively by the plugin's
// OverlayService). Used to recentre the window: the bubble may have been
// dragged, and without this the resized result card inherits that offset and
// spills off-screen. (0,0) with the default CENTER gravity = screen centre.
const MethodChannel _overlayControl = MethodChannel('x-slayer/overlay');

Future<void> _centerOverlay() =>
    _overlayControl.invokeMethod('updateOverlayPosition', {'x': 0, 'y': 0});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kBgCard,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: ScamShieldApp(),
    ),
  );
}

/// ─── Overlay Isolate Entry Point ──────────────────────────────────────────
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayBubbleContent(),
    ),
  );
}

class OverlayBubbleContent extends StatefulWidget {
  const OverlayBubbleContent({super.key});

  @override
  State<OverlayBubbleContent> createState() => _OverlayBubbleContentState();
}

class _OverlayBubbleContentState extends State<OverlayBubbleContent> {
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    // OverlayResultCard is created BY this data arriving, so it can't
    // subscribe to the broadcast stream in time to catch the same event
    // (no replay for late subscribers) — capture it here and pass it down.
    OverlayService.broadcastStream.listen((data) {
      if (data is Map && data.containsKey('risk_score')) {
        // Grow the overlay window so the result card fits and recentre it
        // (the bubble may have been dragged off-centre), then show it.
        FlutterOverlayWindow.resizeOverlay(
            _kResultWidth.toInt(), _kResultHeight.toInt(), false);
        _centerOverlay();
        setState(() {
          _resultData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  // Dismiss the result card and return to the draggable bubble. Handled
  // entirely within the overlay isolate — no round-trip to the main isolate,
  // and the MediaProjection stays alive so the next tap works immediately.
  void _closeResult() {
    FlutterOverlayWindow.resizeOverlay(
        _kBubbleSize.toInt(), _kBubbleSize.toInt(), true);
    setState(() {
      _resultData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _resultData;
    if (data != null) {
      return OverlayResultCard(data: data, onClose: _closeResult);
    }
    return const OverlayBubble();
  }
}

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScamShield Lao',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
