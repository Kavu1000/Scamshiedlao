import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stats.dart';
import '../services/api_service.dart';

final statsProvider = FutureProvider<AppStats>((ref) async {
  return ref.read(apiServiceProvider).getStats();
});
