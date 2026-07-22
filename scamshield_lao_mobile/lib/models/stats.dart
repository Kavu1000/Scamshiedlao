/// Mirrors the backend /api/stats response.
class AppStats {
  final int totalScans;
  final int totalScamsDetected;
  final int totalUserReports;
  final double scamRate;
  final Map<String, int> riskBreakdown;
  final Map<String, int> scamTypeBreakdown;

  const AppStats({
    required this.totalScans,
    required this.totalScamsDetected,
    required this.totalUserReports,
    required this.scamRate,
    required this.riskBreakdown,
    required this.scamTypeBreakdown,
  });

  factory AppStats.fromJson(Map<String, dynamic> json) => AppStats(
        totalScans: json['total_scans'] as int? ?? 0,
        totalScamsDetected: json['total_scams_detected'] as int? ?? 0,
        totalUserReports: json['total_user_reports'] as int? ?? 0,
        scamRate: (json['scam_rate'] as num?)?.toDouble() ?? 0.0,
        riskBreakdown: Map<String, int>.from(
          (json['risk_breakdown'] as Map? ?? {})
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
        ),
        scamTypeBreakdown: Map<String, int>.from(
          (json['scam_type_breakdown'] as Map? ?? {})
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
        ),
      );

  static AppStats get empty => const AppStats(
        totalScans: 0,
        totalScamsDetected: 0,
        totalUserReports: 0,
        scamRate: 0.0,
        riskBreakdown: {},
        scamTypeBreakdown: {},
      );
}
