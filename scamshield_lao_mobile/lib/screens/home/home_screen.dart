import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../config/app_constants.dart';
import '../../providers/scan_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../shared/widgets/ai_verified_badge.dart';
import '../../services/overlay_service.dart';
import '../../services/api_service.dart';
import 'widgets/risk_score_card.dart';
import 'widgets/safe_card.dart';
import 'widgets/skeleton_card.dart';
import 'widgets/status_bar.dart';
import 'widgets/scan_input_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _overlayActive = false;

  @override
  void initState() {
    super.initState();
    _checkOverlayStatus();

    // Listen to overlay messages from the background overlay service thread
    OverlayService.broadcastStream.listen((data) {
      if (data is Map && data['action'] == 'trigger_scan') {
        _handleOverlayScanTrigger();
      } else if (data is Map && data['action'] == 'close_result') {
        ref.read(overlayServiceProvider).closeAll().then((_) {
          // Restart bubble after result card is closed
          ref.read(overlayServiceProvider).showBubble();
        });
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
      setState(() => _overlayActive = false);
    } else {
      final permitted = await overlay.checkPermission();
      if (!permitted) {
        await overlay.requestPermission();
      }
      if (await overlay.checkPermission()) {
        await overlay.showBubble();
        setState(() => _overlayActive = true);
      }
    }
  }

  /// Triggered when overlay bubble is tapped.
  /// Simulates taking a screenshot, performing ML Kit OCR, scanning, and pushing data back to OverlayResultCard.
  Future<void> _handleOverlayScanTrigger() async {
    // Notify overlay bubble to show a loading/scanning spinner
    await FlutterOverlayWindow.shareData({'status': 'scanning'});

    try {
      // For demonstration of on-screen scan, we run a simulated scan on the current screen's typical text content.
      // In a physical device release, this captures MediaProjection screenshots.
      final api = ref.read(apiServiceProvider);
      final result = await api.scanContent(
        text: "URGENT: Win standard \$5,000 weekly salary from home! Join now via WhatsApp: +8562055551234",
        url: "on-screen-live",
        pageTitle: "On-Screen Capture",
      );

      // Share result to the overlay thread (which will display the OverlayResultCard)
      await FlutterOverlayWindow.shareData({
        'risk_score': result.riskScore,
        'risk_level': result.riskLevel.label,
        'scam_type': result.scamType,
        'reasons': result.reasons,
        'is_scam': result.isScam,
      });
    } catch (_) {
      // Clear scanning status on error
      await FlutterOverlayWindow.shareData({'status': 'idle'});
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
                          border: Border.all(color: kError.withValues(alpha: 0.2)),
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
      padding: const EdgeInsets.symmetric(
          horizontal: kSpaceLg, vertical: kSpaceMd),
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
              overlayActive ? Icons.screen_share : Icons.stop_screen_share_outlined,
              color: overlayActive ? kBrandPrimary : kTextMuted,
              size: 22,
            ),
            tooltip: overlayActive ? 'Stop Floating Bubble' : 'Start Floating Bubble',
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
