import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';

/// Mirrors SafeCard from popup/page.tsx.
class SafeCard extends StatelessWidget {
  const SafeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: kRiskLow.withOpacity(0.3),
      child: Column(
        children: [
          const SizedBox(height: kSpaceSm),
          const Text('🛡', style: TextStyle(fontSize: 40)),
          const SizedBox(height: kSpaceMd),
          const Text(
            'Page is Safe',
            style: TextStyle(
              color: kRiskLow,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpaceXs),
          const Text(
            'No scam indicators detected on this page.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpaceSm),
        ],
      ),
    );
  }
}

/// Mirrors UnavailableCard from popup/page.tsx.
class UnavailableCard extends StatelessWidget {
  final String message;
  const UnavailableCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: kSpaceSm),
          const Text('🔍', style: TextStyle(fontSize: 36)),
          const SizedBox(height: kSpaceMd),
          const Text(
            'Not Scanned Yet',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpaceXs),
          Text(
            message,
            style: const TextStyle(color: kTextMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpaceSm),
        ],
      ),
    );
  }
}
