import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_item.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class HistoryState {
  final List<HistoryItem> items;
  final bool loading;
  final String filterLevel; // 'ALL' | 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  final int total;
  final String? error;

  const HistoryState({
    this.items = const [],
    this.loading = false,
    this.filterLevel = 'ALL',
    this.total = 0,
    this.error,
  });

  HistoryState copyWith({
    List<HistoryItem>? items,
    bool? loading,
    String? filterLevel,
    int? total,
    String? error,
  }) =>
      HistoryState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        filterLevel: filterLevel ?? this.filterLevel,
        total: total ?? this.total,
        error: error,
      );

  List<HistoryItem> get filteredItems => filterLevel == 'ALL'
      ? items
      : items.where((i) => i.riskLevel == filterLevel).toList();

  int get scamCount => items.where((i) => i.isScam).length;
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    // Auto-load on first access
    Future.microtask(load);
    return const HistoryState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final sessionId = await ref.read(sessionServiceProvider).getSessionId();
      final response = await ref.read(apiServiceProvider).getHistory(
            sessionId: sessionId,
            limit: 50,
          );
      state = state.copyWith(
        items: response.items,
        total: response.total,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter(String level) =>
      state = state.copyWith(filterLevel: level);
}

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
