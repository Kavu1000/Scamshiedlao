import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/app_constants.dart';

/// Skeleton loading card — mirrors SkeletonCard from popup/page.tsx.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceLg),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorder),
      ),
      child: Shimmer.fromColors(
        baseColor: kBgElevated,
        highlightColor: kBgCardHover,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(0.55, 14),
            const SizedBox(height: 12),
            _bar(0.35, 40),
            const SizedBox(height: 12),
            _bar(1.0, 6),
            const SizedBox(height: 12),
            _bar(1.0, 12),
            const SizedBox(height: 8),
            _bar(0.75, 12),
          ],
        ),
      ),
    );
  }

  Widget _bar(double widthFactor, double height) => FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: kBgElevated,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}
