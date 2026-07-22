/// Mirrors the backend ScamReport Pydantic model.
class ScamReport {
  final String url;
  final String pageTitle;
  final String description;
  final String scamType;
  final String? reporterSession;

  const ScamReport({
    required this.url,
    required this.pageTitle,
    required this.description,
    required this.scamType,
    this.reporterSession,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'page_title': pageTitle,
        'description': description,
        'scam_type': scamType,
        if (reporterSession != null) 'reporter_session': reporterSession,
      };
}

/// Mirrors the backend ScamReportResponse.
class ScamReportResponse {
  final String id;
  final String message;
  final DateTime createdAt;

  const ScamReportResponse({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory ScamReportResponse.fromJson(Map<String, dynamic> json) =>
      ScamReportResponse(
        id: json['id'] as String,
        message: json['message'] as String,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
