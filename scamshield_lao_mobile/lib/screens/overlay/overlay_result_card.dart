import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

class OverlayResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const OverlayResultCard({super.key, required this.data, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final int riskScore = data['risk_score'] as int;
    final String riskLevel = data['risk_level'] as String? ?? 'LOW';
    final String scamType = data['scam_type'] as String? ?? 'none';
    final bool isScam = data['is_scam'] as bool? ?? false;
    final List<dynamic> reasons = data['reasons'] as List? ?? [];

    final Color riskColor = _getRiskColor(riskLevel);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(kSpaceMd),
            child: ConstrainedBox(
              // Fill the overlay window width but never exceed a sensible max.
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                width: double.infinity,
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text(isScam ? '🚨' : '🛡', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: kSpaceSm),
                          Expanded(
                            child: Text(
                              isScam ? 'Scam Detected!' : 'Content Safe',
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: kTextMuted, size: 20),
                            onPressed: onClose,
                            padding: const EdgeInsets.all(4),
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
                            const SizedBox(width: kSpaceSm),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: riskColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(kRadiusSm),
                                  ),
                                  child: Text(
                                    scamType.toUpperCase().replaceAll('_', ' '),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: kSpaceMd),

                      // Reasons list
                      if (reasons.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: reasons.take(3).map((r) {
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
            ),
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
