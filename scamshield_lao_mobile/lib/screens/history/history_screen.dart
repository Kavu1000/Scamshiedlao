import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_constants.dart';
import '../../models/history_item.dart';
import '../../providers/history_provider.dart';
import '../../shared/widgets/risk_badge.dart';
import '../../models/scan_result.dart';
import '../../shared/extensions/string_extensions.dart';
import '../../shared/extensions/color_extensions.dart';

/// History screen — mirrors popup/src/app/history/page.tsx.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan History',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${state.items.length} scans · ${state.scamCount} threats',
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        ref.read(historyProvider.notifier).load(),
                    icon: const Icon(Icons.refresh,
                        color: kTextMuted, size: 20),
                  ),
                ],
              ),
            ),

            // Filter tabs
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceLg, vertical: kSpaceSm),
              decoration: const BoxDecoration(
                color: kBgBase,
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(
                children: _filters.map((f) {
                  final selected = state.filterLevel == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(historyProvider.notifier).setFilter(f),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? kBrandPrimary.withOpacity(0.15)
                              : kBgCard,
                          borderRadius:
                              BorderRadius.circular(kRadiusSm),
                          border: Border.all(
                            color: selected ? kBorderAccent : kBorder,
                          ),
                        ),
                        child: Text(
                          f,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? kBrandPrimary : kTextMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // List
            Expanded(
              child: state.loading
                  ? _buildSkeletons()
                  : state.filteredItems.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(historyProvider.notifier).load(),
                          color: kBrandPrimary,
                          backgroundColor: kBgCard,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(kSpaceLg),
                            itemCount: state.filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: kSpaceSm),
                            itemBuilder: (context, i) =>
                                _HistoryTile(item: state.filteredItems[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() => ListView.separated(
        padding: const EdgeInsets.all(kSpaceLg),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: kSpaceSm),
        itemBuilder: (_, __) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
        ),
      );

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 40)),
            SizedBox(height: kSpaceMd),
            Text(
              'No scan history yet.',
              style: TextStyle(color: kTextMuted, fontSize: 14),
            ),
            SizedBox(height: kSpaceXs),
            Text(
              'Paste a URL in the Scan tab to get started.',
              style: TextStyle(color: kTextMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final level = RiskLevel.fromString(item.riskLevel);
    final timeStr = DateFormat('HH:mm, MMM d').format(item.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpaceMd, vertical: kSpaceMd),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.url.truncateUrl(),
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeStr,
                style:
                    const TextStyle(color: kTextMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: kSpaceXs),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.pageTitle.isNotEmpty
                      ? item.pageTitle
                      : 'Untitled Page',
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RiskBadge(level: level, score: item.riskScore),
            ],
          ),
          if (item.scamType.isNotEmpty && item.scamType != 'none') ...[
            const SizedBox(height: kSpaceXs),
            Text(
              item.scamType.toUpperCase().replaceAll('_', ' '),
              style: TextStyle(color: level.color, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
