import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../config/app_constants.dart';
import '../../services/overlay_service.dart';

class OverlayResultCard extends StatefulWidget {
  const OverlayResultCard({super.key});

  @override
  State<OverlayResultCard> createState() => _OverlayResultCardState();
}

class _OverlayResultCardState extends State<OverlayResultCard> {
  Map<String, dynamic>? _scanData;

  @override
  void initState() {
    super.initState();
    OverlayService.broadcastStream.listen((data) {
      if (data is Map && data.containsKey('risk_score')) {
        setState(() {
          _scanData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  void _close() {
    FlutterOverlayWindow.shareData({'action': 'close_result'});
  }

  @override
  Widget build(BuildContext context) {
    if (_scanData == null) return const SizedBox.shrink();

    final int riskScore = _scanData!['risk_score'] as int;
    final String riskLevel = _scanData!['risk_level'] as String? ?? 'LOW';
    final String scamType = _scanData!['scam_type'] as String? ?? 'none';
    final bool isScam = _scanData!['is_scam'] as bool? ?? false;
    final List<dynamic> reasons = _scanData!['reasons'] as List? ?? [];

    final Color riskColor = _getRiskColor(riskLevel);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(kSpaceLg),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: Border.all(color: riskColor.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(isScam ? '🚨' : '🛡', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: kSpaceSm),
                      Text(
                        isScam ? 'Scam Detected!' : 'Content Safe',
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextMuted, size: 18),
                    onPressed: _close,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: kSpaceLg),

              // Score
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$riskScore',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const Text(' / 100', style: TextStyle(color: kTextMuted, fontSize: 14)),
                  if (scamType != 'none') ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(kRadiusSm),
                      ),
                      child: Text(
                        scamType.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: kSpaceMd),

              // Reasons list
              if (reasons.isNotEmpty)
                Column(
                  children: reasons.take(2).map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('▸ ', style: TextStyle(color: riskColor, fontSize: 12)),
                          Expanded(
                            child: Text(
                              r.toString(),
                              style: const TextStyle(color: kTextSecondary, fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return kRiskCritical;
      case 'HIGH':
        return kRiskHigh;
      case 'MEDIUM':
        return kRiskMedium;
      default:
        return kRiskLow;
    }
  }
}
