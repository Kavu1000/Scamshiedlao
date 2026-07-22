import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../models/stats.dart';
import '../../providers/stats_provider.dart';
import '../../shared/extensions/color_extensions.dart';
import '../../models/scan_result.dart';

/// Stats screen — dedicated dashboard for /api/stats endpoint.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: kBgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceLg, vertical: kSpaceMd),
              decoration: const BoxDecoration(
                color: kBgBase,
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistics',
                        style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Aggregate detection data',
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.invalidate(statsProvider),
                    icon: const Icon(Icons.refresh,
                        color: kTextMuted, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: statsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: kBrandPrimary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚠', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: kSpaceMd),
                      Text(
                        'Failed to load stats.\nIs the backend running?',
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                data: (stats) => _StatsBody(stats: stats),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final AppStats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top metric cards
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total Scans',
                  value: '${stats.totalScans}',
                  icon: '🔍',
                  color: kBrandPrimary,
                ),
              ),
              const SizedBox(width: kSpaceSm),
              Expanded(
                child: _MetricCard(
                  label: 'Scams Found',
                  value: '${stats.totalScamsDetected}',
                  icon: '🚨',
                  color: kRiskCritical,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpaceSm),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Scam Rate',
                  value: '${stats.scamRate}%',
                  icon: '📊',
                  color: kRiskHigh,
                ),
              ),
              const SizedBox(width: kSpaceSm),
              Expanded(
                child: _MetricCard(
                  label: 'User Reports',
                  value: '${stats.totalUserReports}',
                  icon: '📝',
                  color: kBrandSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpaceXl),

          // Risk breakdown
          if (stats.riskBreakdown.isNotEmpty) ...[
            const Text(
              'Risk Level Breakdown',
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: kSpaceMd),
            _RiskBreakdownBar(breakdown: stats.riskBreakdown),
            const SizedBox(height: kSpaceXl),
          ],

          // Scam type breakdown
          if (stats.scamTypeBreakdown.isNotEmpty) ...[
            const Text(
              'Top Scam Categories',
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: kSpaceMd),
            _ScamTypeList(breakdown: stats.scamTypeBreakdown),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceLg),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: kSpaceSm),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: kTextMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RiskBreakdownBar extends StatelessWidget {
  final Map<String, int> breakdown;
  const _RiskBreakdownBar({required this.breakdown});

  static const _order = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: _order.where((k) => breakdown.containsKey(k)).map((key) {
        final count = breakdown[key]!;
        final pct = count / total;
        final level = RiskLevel.fromString(key);
        return Padding(
          padding: const EdgeInsets.only(bottom: kSpaceSm),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  key,
                  style: TextStyle(
                      color: level.color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: kBorder,
                            borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                              color: level.color,
                              borderRadius: BorderRadius.circular(4))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpaceSm),
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScamTypeList extends StatelessWidget {
  final Map<String, int> breakdown;
  const _ScamTypeList({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = breakdown.values.fold(0, (a, b) => a + b);

    return Column(
      children: entries.take(6).map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: kSpaceSm),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpaceMd, vertical: kSpaceSm),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(kRadiusSm),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      color: kBrandPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
