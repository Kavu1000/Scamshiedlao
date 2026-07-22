import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/scan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status bar matching the popup's .status-bar element.
class ScanStatusBar extends ConsumerWidget {
  const ScanStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;

    final (statusText, dotColor) = _resolve(scanState, isOnline);

    return Row(
      children: [
        _AnimatedDot(color: dotColor, scanning: scanState.isScanning),
        const SizedBox(width: kSpaceSm),
        Expanded(
          child: Text(
            statusText,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  (String, Color) _resolve(ScanState state, bool online) {
    if (!online) return ('Backend Offline', kError);
    if (state.isScanning) return ('Scanning... (ກຳລັງກວດ)', kBrandPrimary);
    if (state.result?.isScam == true) {
      return ('Scam detected — ${state.result!.riskScore}%', kRiskCritical);
    }
    if (state.result != null) return ('Page is Safe ✓', kRiskLow);
    return ('Ready to scan', kTextMuted);
  }
}

class _AnimatedDot extends StatefulWidget {
  final Color color;
  final bool scanning;

  const _AnimatedDot({required this.color, required this.scanning});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.scanning) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      );
    }
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
