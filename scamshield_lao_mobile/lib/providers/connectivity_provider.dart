import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

/// Polls backend health every 30 seconds.
/// Mirrors the backendOnline / checkHealth() logic from popup/page.tsx.
final connectivityProvider =
    AsyncNotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class ConnectivityNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => _check();

  Future<bool> _check() async {
    try {
      final settings = await ref.read(settingsProvider.future);
      ref.read(apiServiceProvider).setBaseUrl(settings.backendUrl);
    } catch (_) {}
    return ref.read(apiServiceProvider).checkHealth();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _check());
  }
}
