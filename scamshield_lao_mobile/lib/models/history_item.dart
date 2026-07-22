/// Mirrors the backend scan_sessions collection fields.
class HistoryItem {
  final String sessionId;
  final String url;
  final String pageTitle;
  final int riskScore;
  final String riskLevel;
  final String scamType;
  final bool isScam;
  final DateTime createdAt;

  const HistoryItem({
    required this.sessionId,
    required this.url,
    required this.pageTitle,
    required this.riskScore,
    required this.riskLevel,
    required this.scamType,
    required this.isScam,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        sessionId: json['session_id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        pageTitle: json['page_title'] as String? ?? '',
        riskScore: json['risk_score'] as int? ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'LOW',
        scamType: json['scam_type'] as String? ?? 'none',
        isScam: json['is_scam'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class HistoryResponse {
  final List<HistoryItem> items;
  final int total;
  final int page;
  final int limit;

  const HistoryResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      HistoryResponse(
        items: (json['items'] as List? ?? [])
            .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 1,
        limit: json['limit'] as int? ?? 20,
      );
}
