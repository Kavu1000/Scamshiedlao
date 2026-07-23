import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../config/app_constants.dart';
import '../../providers/scan_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../shared/widgets/ai_verified_badge.dart';
import '../../services/overlay_service.dart';
import '../../services/screen_capture_service.dart';
import '../../services/screen_scanner.dart';
import 'widgets/risk_score_card.dart';
import 'widgets/safe_card.dart';
import 'widgets/skeleton_card.dart';
import 'widgets/status_bar.dart';
import 'widgets/scan_input_section.dart';

/// flutter_overlay_window's shareData only reliably relays main app ->
/// overlay; a message sent from the overlay isolate never reaches the main
/// isolate. This direct channel (wired up natively in MainActivity.kt) is our
/// own bridge for signals coming from the overlay bubble/result card.
const _overlayBridge =
    MethodChannel('com.scamshield.scamshield_lao_mobile/overlay_bridge');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _overlayActive = false;
  bool _overlayScanInProgress = false;

  @override
  void initState() {
    super.initState();
    _checkOverlayStatus();

    // Signals from the overlay bubble/result card (see overlay_bridge in
    // MainActivity.kt — flutter_overlay_window's own shareData can't carry
    // these overlay -> main isolate).
    _overlayBridge.setMethodCallHandler((call) async {
      if (call.method == 'triggerScan') {
        _handleOverlayScanTrigger();
      } else if (call.method == 'closeResult') {
        await ref.read(overlayServiceProvider).closeAll();
        // Restart bubble after result card is closed
        await ref.read(overlayServiceProvider).showBubble();
      }
    });
  }

  Future<void> _checkOverlayStatus() async {
    final active = await FlutterOverlayWindow.isActive();
    setState(() {
      _overlayActive = active;
    });
  }

  Future<void> _toggleOverlay() async {
    final overlay = ref.read(overlayServiceProvider);
    if (_overlayActive) {
      await overlay.closeAll();
      await ref.read(screenCaptureServiceProvider).stopProjection();
      setState(() => _overlayActive = false);
    } else {
      final permitted = await overlay.checkPermission();
      if (!permitted) {
        await overlay.requestPermission();
      }
      if (!await overlay.checkPermission()) return;

      // Screen-capture consent must be granted up front, while this app is
      // still in the foreground — it can't be requested once the bubble is
      // tapped over another app.
      final captureGranted =
          await ref.read(screenCaptureServiceProvider).requestPermission();
      if (!captureGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Screen-capture permission is required for the floating bubble to scan on-screen content.'),
            ),
          );
        }
        return;
      }

      await overlay.showBubble();
      setState(() => _overlayActive = true);
    }
  }

  /// Triggered when overlay bubble is tapped while another app (e.g. Messenger)
  /// is in the foreground. Grabs a screenshot of whatever is currently on
  /// screen via MediaProjection, runs on-device OCR, and scans the extracted
  /// text — then pushes the result back to the OverlayResultCard.
  Future<void> _handleOverlayScanTrigger() async {
    if (_overlayScanInProgress) return;
    _overlayScanInProgress = true;

    // Notify overlay bubble to show a loading/scanning spinner
    await FlutterOverlayWindow.shareData({'status': 'scanning'});

    try {
      final imagePath = await ref.read(screenCaptureServiceProvider).capture();
      if (imagePath == null) {
        await FlutterOverlayWindow.shareData({'status': 'idle'});
        return;
      }

      final result =
          await ref.read(screenScannerProvider).scanImageScreen(imagePath);

      // Share result to the overlay thread (which will display the OverlayResultCard)
      await FlutterOverlayWindow.shareData({
        'risk_score': result.riskScore,
        'risk_level': result.riskLevel.label,
        'scam_type': result.scamType,
        'reasons': result.reasons,
        'is_scam': result.isScam,
      });
    } catch (e, stackTrace) {
      debugPrint('[ScamShield] Overlay scan error: $e\n$stackTrace');
      await FlutterOverlayWindow.shareData({
        'risk_score': 0,
        'risk_level': 'LOW',
        'scam_type': 'none',
        'reasons': ['Scan error: ${e.toString()}'],
        'is_scam': false,
      });
    } finally {
      _overlayScanInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: kBgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Scanning progress bar
            if (scanState.isScanning)
              LinearProgressIndicator(
                backgroundColor: kBgCard,
                color: kBrandPrimary,
                minHeight: 2,
              ),

            // Header
            _Header(
              isOnline: isOnline,
              overlayActive: _overlayActive,
              onToggleOverlay: _toggleOverlay,
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(kSpaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceMd, vertical: kSpaceSm),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        border: Border.all(color: kBorder),
                      ),
                      child: const ScanStatusBar(),
                    ),
                    const SizedBox(height: kSpaceMd),

                    // Scan input
                    ScanInputSection(
                      disabled: scanState.isScanning || !isOnline,
                      onScan: (text, url) {
                        ref.read(scanProvider.notifier).scan(
                              text: text,
                              url: url,
                              pageTitle: url.isNotEmpty ? url : 'Manual Scan',
                            );
                      },
                    ),
                    const SizedBox(height: kSpaceMd),

                    // Result area
                    if (scanState.isScanning)
                      const SkeletonCard()
                    else if (scanState.result?.isScam == true) ...[
                      // Threat alert banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSpaceMd, vertical: kSpaceSm),
                        decoration: BoxDecoration(
                          color: kRiskCritical.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(kRadiusSm),
                          border: Border.all(
                              color: kRiskCritical.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          children: [
                            Text('⚠', style: TextStyle(fontSize: 20)),
                            SizedBox(width: kSpaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scam Detected!',
                                    style: TextStyle(
                                      color: kRiskCritical,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Review the risk analysis below.',
                                    style: TextStyle(
                                        color: kTextMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: kSpaceMd),
                      RiskScoreCard(result: scanState.result!),
                    ] else if (scanState.result != null)
                      const SafeCard()
                    else if (scanState.isError)
                      UnavailableCard(
                        message: scanState.errorMessage ??
                            'Scan failed. Please try again.',
                      )
                    else
                      const UnavailableCard(
                        message:
                            'Paste a URL or text above and tap Scan to check for scam indicators.',
                      ),

                    // Backend offline warning
                    if (!isOnline) ...[
                      const SizedBox(height: kSpaceMd),
                      Container(
                        padding: const EdgeInsets.all(kSpaceMd),
                        decoration: BoxDecoration(
                          color: kError.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(kRadiusSm),
                          border:
                              Border.all(color: kError.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          '⚠ Backend offline — start the Python server on port 8000',
                          style: TextStyle(color: kError, fontSize: 12),
                        ),
                      ),
                    ],

                    // Footer result info
                    if (scanState.result != null) ...[
                      const SizedBox(height: kSpaceMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              scanState.result!.url.isNotEmpty
                                  ? scanState.result!.url
                                  : 'Manual text scan',
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (scanState.result!.aiAnalyzed)
                            const AiVerifiedBadge(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isOnline;
  final bool overlayActive;
  final void Function() onToggleOverlay;

  const _Header({
    required this.isOnline,
    required this.overlayActive,
    required this.onToggleOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpaceLg, vertical: kSpaceMd),
      decoration: const BoxDecoration(
        color: kBgBase,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          // Logo + brand
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBrandSecondary, Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            child: const Center(
              child: Text('🛡', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: kSpaceMd),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ScamShield Lao',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Real-time Protection',
                style: TextStyle(color: kTextMuted, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Floating overlay toggle button
          IconButton(
            onPressed: onToggleOverlay,
            icon: Icon(
              overlayActive
                  ? Icons.screen_share
                  : Icons.stop_screen_share_outlined,
              color: overlayActive ? kBrandPrimary : kTextMuted,
              size: 22,
            ),
            tooltip: overlayActive
                ? 'Stop Floating Bubble'
                : 'Start Floating Bubble',
          ),
          const SizedBox(width: kSpaceSm),
          // Backend status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? kRiskLow : kError,
            ),
          ),
        ],
      ),
    );
  }
}
