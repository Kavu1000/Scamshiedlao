import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

/// "✦ AI Verified" badge matching the popup's .ai-badge CSS class.
class AiVerifiedBadge extends StatelessWidget {
  const AiVerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kBrandGlow,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: kBrandPrimary.withOpacity(0.3)),
      ),
      child: const Text(
        '✦ AI Verified',
        style: TextStyle(
          color: kBrandPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
