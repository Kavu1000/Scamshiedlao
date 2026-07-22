import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() =>
      ref.read(settingsServiceProvider).load();

  Future<void> save(AppSettings settings) async {
    state = const AsyncLoading();
    await ref.read(settingsServiceProvider).save(settings);
    state = AsyncData(settings);
  }
}
