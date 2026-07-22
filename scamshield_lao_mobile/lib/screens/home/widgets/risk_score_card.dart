import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../../../models/scan_result.dart';
import '../../../shared/widgets/risk_badge.dart';
import '../../../shared/widgets/ai_verified_badge.dart';
import '../../../shared/widgets/animated_progress_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/extensions/color_extensions.dart';

/// Animated risk score card — mirrors RiskScoreCard from popup/page.tsx.
class RiskScoreCard extends StatefulWidget {
  final ScanResult result;

  const RiskScoreCard({super.key, required this.result});

  @override
  State<RiskScoreCard> createState() => _RiskScoreCardState();
}

class _RiskScoreCardState extends State<RiskScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scoreAnimation = IntTween(begin: 0, end: widget.result.riskScore)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100), _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.result.riskLevel;
    return GlassCard(
      borderColor: level.borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Risk Analysis',
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  if (widget.result.aiAnalyzed) ...[
                    const AiVerifiedBadge(),
                    const SizedBox(width: kSpaceSm),
                  ],
                  RiskBadge(level: level),
                ],
              ),
            ],
          ),
          const SizedBox(height: kSpaceMd),

          // Animated score
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (_, __) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_scoreAnimation.value}',
                  style: TextStyle(
                    color: level.color,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    '/ 100',
                    style: TextStyle(color: kTextMuted, fontSize: 16),
                  ),
                ),
                if (widget.result.scamType != 'none') ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSpaceSm, vertical: kSpaceXs),
                    decoration: BoxDecoration(
                      color: level.bgColor,
                      borderRadius: BorderRadius.circular(kRadiusSm),
                    ),
                    child: Text(
                      widget.result.scamType
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: TextStyle(
                        color: level.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSpaceMd),

          // Progress bar
          AnimatedProgressBar(
              score: widget.result.riskScore, level: level),
          const SizedBox(height: kSpaceLg),

          // Reasons
          if (widget.result.reasons.isNotEmpty)
            ...widget.result.reasons.take(3).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: kSpaceSm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '▸ ',
                          style: TextStyle(
                              color: level.color, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
