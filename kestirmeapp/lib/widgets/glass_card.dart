import 'package:flutter/material.dart';

/// Glassmorphism Kart Widget'ı
/// Premium blur ve semi-transparent arka plan
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? glowColor;
  
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = glowColor ?? theme.colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.3),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

/// Premium arka plan container
/// Subtle gradient overlay
class PremiumBackground extends StatelessWidget {
  final Widget child;
  
  const PremiumBackground({
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
          ],
        ),
      ),
      child: child,
    );
  }
}
