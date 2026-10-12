import 'package:flutter/material.dart';

/// AI yazarken gösterilen animasyonlu typing indicator
class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({super.key});

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0, colorScheme.primary),
          const SizedBox(width: 4),
          _buildDot(1, colorScheme.primary),
          const SizedBox(width: 4),
          _buildDot(2, colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double delay = index * 0.2;
        final double value = (_controller.value - delay) % 1.0;
        final double opacity = value < 0.5 ? value * 2 : (1 - value) * 2;

        return Opacity(
          opacity: opacity.clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
