import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../models/scan_result.dart';

/// Colored risk-level badge matching the popup's .risk-badge CSS classes.
class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final int? score;
  final double fontSize;

  const RiskBadge({
    super.key,
    required this.level,
    this.score,
    this.fontSize = 11,
  });

  Color get _color {
    switch (level) {
      case RiskLevel.critical:
        return kRiskCritical;
      case RiskLevel.high:
        return kRiskHigh;
      case RiskLevel.medium:
        return kRiskMedium;
      case RiskLevel.low:
        return kRiskLow;
    }
  }

  String get _emoji {
    switch (level) {
      case RiskLevel.critical:
        return '🔴';
      case RiskLevel.high:
        return '🟠';
      case RiskLevel.medium:
        return '🟡';
      case RiskLevel.low:
        return '🟢';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = score != null ? '${score}%' : level.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Text(
        '$_emoji $label',
        style: TextStyle(
          color: _color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
