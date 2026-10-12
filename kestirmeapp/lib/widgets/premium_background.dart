import 'package:flutter/material.dart';

/// Stabil premium gradient arka plan
/// Particle yerine performanslı gradient
class PremiumGradientBackground extends StatelessWidget {
  final Widget child;
  
  const PremiumGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF000000),
            const Color(0xFF0A0A0A).withOpacity(0.8),
            const Color(0xFF00D4FF).withOpacity(0.05),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Dönen makas loading (particle yerine)
class ScissorsLoading extends StatefulWidget {
  final double size;
  
  const ScissorsLoading({
    super.key,
    this.size = 40,
  });

  @override
  State<ScissorsLoading> createState() => _ScissorsLoadingState();
}

class _ScissorsLoadingState extends State<ScissorsLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
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
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Icon(
          Icons.content_cut,
          size: widget.size,
          color: const Color(0xFF00D4FF),
        ),
      ),
    );
  }
}
