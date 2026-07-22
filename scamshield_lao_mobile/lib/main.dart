import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/app_constants.dart';
import 'screens/overlay/overlay_bubble.dart';
import 'screens/overlay/overlay_result_card.dart';
import 'services/overlay_service.dart';

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
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    OverlayService.broadcastStream.listen((data) {
      if (data is Map && data.containsKey('risk_score')) {
        setState(() {
          _showResult = true;
        });
      } else if (data is Map && data['action'] == 'close_result') {
        setState(() {
          _showResult = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return const OverlayResultCard();
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
