import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../models/scan_result.dart';

/// Animated progress bar matching the popup's .progress-bar-fill CSS animation.
class AnimatedProgressBar extends StatefulWidget {
  final int score;
  final RiskLevel level;

  const AnimatedProgressBar({
    super.key,
    required this.score,
    required this.level,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _animation = Tween<double>(begin: 0, end: widget.score / 100)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.level) {
      case RiskLevel.critical:
        return kRiskCritical;
      case RiskLevel.high:
        return kRiskHigh;
      case RiskLevel.medium:
        return kRiskMedium;
      case RiskLevel.low:
        return kRiskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        height: 6,
        decoration: BoxDecoration(
          color: kBorder,
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
