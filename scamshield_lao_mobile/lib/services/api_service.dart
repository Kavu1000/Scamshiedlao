import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_constants.dart';
import '../models/scan_result.dart';
import '../models/history_item.dart';
import '../models/scam_report.dart';
import '../models/stats.dart';

/// Provider for the singleton ApiService.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: kApiTimeoutSeconds),
      receiveTimeout: const Duration(seconds: kApiTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Update the base URL (from settings).
  void setBaseUrl(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanUrl = trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
    _dio.options.baseUrl = cleanUrl;
  }

  /// POST /api/scan
  /// Mirrors scanContent() from api.ts
  Future<ScanResult> scanContent({
    required String text,
    required String url,
    required String pageTitle,
    String? sessionId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/scan',
      data: {
        'text': text,
        'url': url,
        'page_title': pageTitle,
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return ScanResult.fromJson(response.data!);
  }

  /// GET /api/history
  /// Mirrors getHistory() from api.ts
  Future<HistoryResponse> getHistory({
    required String sessionId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/history',
      queryParameters: {
        'session_id': sessionId,
        'page': page,
        'limit': limit,
      },
    );
    return HistoryResponse.fromJson(response.data!);
  }

  /// POST /api/report
  /// Mirrors submitReport() from api.ts
  Future<ScamReportResponse> submitReport(ScamReport report) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/report',
      data: report.toJson(),
    );
    return ScamReportResponse.fromJson(response.data!);
  }

  /// GET /api/stats
  /// Mirrors getStats() from api.ts
  Future<AppStats> getStats() async {
    final response = await _dio.get<Map<String, dynamic>>('/stats');
    return AppStats.fromJson(response.data!);
  }

  /// GET /api/health
  /// Mirrors checkHealth() from api.ts with 3s timeout
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get<dynamic>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: kHealthCheckTimeoutSeconds),
          receiveTimeout: const Duration(seconds: kHealthCheckTimeoutSeconds),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
