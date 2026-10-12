import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';

/// Premium animated background with floating particles
/// Antigravity-style interactive background
class AnimatedPremiumBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedPremiumBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedPremiumBackground> createState() => _AnimatedPremiumBackgroundState();
}

class _AnimatedPremiumBackgroundState extends State<AnimatedPremiumBackground>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      behaviour: RandomParticleBehaviour(
        options: ParticleOptions(
          baseColor: const Color(0xFF00D4FF),
          spawnOpacity: 0.0,
          opacityChangeRate: 0.25,
          minOpacity: 0.1,
          maxOpacity: 0.3,
          spawnMinSpeed: 10.0,
          spawnMaxSpeed: 30.0,
          spawnMinRadius: 2.0,
          spawnMaxRadius: 6.0,
          particleCount: 25,
        ),
      ),
      vsync: this,
      child: Container(
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
        child: widget.child,
      ),
    );
  }
}
