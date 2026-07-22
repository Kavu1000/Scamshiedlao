import 'package:flutter/material.dart';
import '../../models/scan_result.dart';
import '../../config/app_constants.dart';

extension RiskLevelColor on RiskLevel {
  Color get color {
    switch (this) {
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

  Color get bgColor => color.withOpacity(0.10);
  Color get borderColor => color.withOpacity(0.30);

  static RiskLevel fromString(String s) {
    switch (s.toUpperCase()) {
      case 'CRITICAL':
        return RiskLevel.critical;
      case 'HIGH':
        return RiskLevel.high;
      case 'MEDIUM':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}
