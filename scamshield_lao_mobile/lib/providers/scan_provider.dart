import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';

/// Scan state machine
enum ScanStatus { idle, scanning, success, error }

class ScanState {
  final ScanStatus status;
  final ScanResult? result;
  final String? errorMessage;

  const ScanState({
    this.status = ScanStatus.idle,
    this.result,
    this.errorMessage,
  });

  ScanState copyWith({
    ScanStatus? status,
    ScanResult? result,
    String? errorMessage,
  }) =>
      ScanState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isScanning => status == ScanStatus.scanning;
  bool get hasResult => result != null;
  bool get isError => status == ScanStatus.error;
}

class ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  /// Triggers a scan — mirrors triggerScan() from popup/page.tsx.
  Future<void> scan({
    required String text,
    required String url,
    String pageTitle = '',
  }) async {
    state = const ScanState(status: ScanStatus.scanning);

    try {
      final settings = await ref.read(settingsServiceProvider).load();
      final api = ref.read(apiServiceProvider);
      api.setBaseUrl(settings.backendUrl);

      final sessionId = await ref.read(sessionServiceProvider).getSessionId();

      final result = await api.scanContent(
        text: text,
        url: url,
        pageTitle: pageTitle,
        sessionId: sessionId,
      );

      state = ScanState(status: ScanStatus.success, result: result);
    } catch (e) {
      state = ScanState(
        status: ScanStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const ScanState();
}

final scanProvider = NotifierProvider<ScanNotifier, ScanState>(ScanNotifier.new);
