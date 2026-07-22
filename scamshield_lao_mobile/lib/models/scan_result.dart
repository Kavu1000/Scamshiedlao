/// Mirrors the backend ScanResult Pydantic model.
class ScanResult {
  final int riskScore;
  final RiskLevel riskLevel;
  final String scamType;
  final List<String> reasons;
  final List<String> flaggedPhrases;
  final bool isScam;
  final double confidence;
  final int heuristicScore;
  final bool aiAnalyzed;
  final String url;
  final String pageTitle;
  final bool fromCache;

  const ScanResult({
    required this.riskScore,
    required this.riskLevel,
    required this.scamType,
    required this.reasons,
    required this.flaggedPhrases,
    required this.isScam,
    required this.confidence,
    required this.heuristicScore,
    required this.aiAnalyzed,
    required this.url,
    required this.pageTitle,
    required this.fromCache,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        riskScore: json['risk_score'] as int,
        riskLevel: RiskLevel.fromString(json['risk_level'] as String),
        scamType: json['scam_type'] as String? ?? 'none',
        reasons: List<String>.from(json['reasons'] as List? ?? []),
        flaggedPhrases:
            List<String>.from(json['flagged_phrases'] as List? ?? []),
        isScam: json['is_scam'] as bool? ?? false,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        heuristicScore: json['heuristic_score'] as int? ?? 0,
        aiAnalyzed: json['ai_analyzed'] as bool? ?? false,
        url: json['url'] as String? ?? '',
        pageTitle: json['page_title'] as String? ?? '',
        fromCache: json['from_cache'] as bool? ?? false,
      );
}

enum RiskLevel {
  low,
  medium,
  high,
  critical;

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

  String get label => name.toUpperCase();
}
