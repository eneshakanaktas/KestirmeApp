import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'auth_gate_page.dart';
import '../widgets/animated_premium_background.dart';

/// Ultra Premium Splash Page
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthGatePage(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.content_cut, size: 120, color: const Color(0xFF00D4FF))
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 1500.ms, color: const Color(0xFFFFD700)),
              
              const SizedBox(height: 40),
              
              Text(
                'KESTIRME',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(color: const Color(0xFF00D4FF).withOpacity(0.5), blurRadius: 20),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 16),
              
              const Text(
                'Premium Berber Deneyimi',
                style: TextStyle(fontSize: 16, color: Color(0xFF00D4FF), letterSpacing: 2),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 60),
              
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF00D4FF)),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
