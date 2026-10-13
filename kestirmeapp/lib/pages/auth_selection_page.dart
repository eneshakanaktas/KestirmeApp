import 'package:flutter/material.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'customer_auth_page.dart';
import 'barber_auth_page.dart';
import 'auth_gate_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Ultra Premium Auth Selection Page
/// Müşteri veya Berber seçimi yapılan sayfa
class AuthSelectionPage extends StatelessWidget {
  const AuthSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ═══════════════════════════════════════════════════
                    // ANIMATED SCISSORS LOGO
                    // ═══════════════════════════════════════════════════
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00D4FF).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4FF).withOpacity(0.6),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.content_cut,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms)
                      .then()
                      .animate()
                      .fadeIn(duration: 800.ms),
                    
                    const SizedBox(height: 40),
                    
                    // ═══════════════════════════════════════════════════
                    // TITLE
                    // ═══════════════════════════════════════════════════
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFFFFD700)],
                      ).createShader(bounds),
                      child: const Text(
                        'KESTİRME',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 12,
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.3),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Premium Berber Deneyimi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 4,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    
                    const SizedBox(height: 80),
                    
                    // ═══════════════════════════════════════════════════
                    // SELECTION CARDS
                    // ═══════════════════════════════════════════════════
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          // CUSTOMER CARD
                          _buildSelectionCard(
                            context: context,
                            title: 'MÜŞTERİ',
                            subtitle: 'Randevu al, berberini bul',
                            icon: Icons.person,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                            ),
                            shadowColor: const Color(0xFF00D4FF),
                            onTap: () => kMisafirGirisiAcik
                                ? _misafirMusteriGirisi(context)
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CustomerAuthPage()),
                                  ),
                          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),

                          if (kMisafirGirisiAcik)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerAuthPage()),
                              ),
                              child: Text(
                                'Hesabımla müşteri girişi yap',
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // BARBER CARD
                          _buildSelectionCard(
                            context: context,
                            title: 'BERBER',
                            subtitle: 'Salonunu yönet, randevuları takip et',
                            icon: Icons.content_cut,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            ),
                            shadowColor: const Color(0xFFFFD700),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BarberAuthPage()),
                            ),
                          ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.3),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // ═══════════════════════════════════════════════════
                    // VERSION INFO
                    // ═══════════════════════════════════════════════════
                    Text(
                      'v2.0 • Premium Edition',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// GEÇİCİ (test): Müşteri kartına basınca otomatik misafir (anonim) giriş yapar.
  /// Giriş olunca AuthGatePage kullanıcıyı müşteri paneline taşır.
  Future<void> _misafirMusteriGirisi(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Misafir girişi yapılamadı. Firebase > Authentication > Sign-in method bölümünde "Anonymous" açık olmalı. ($e)',
            ),
          ),
        );
      }
    }
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: shadowColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              
              const SizedBox(width: 20),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shadowColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: shadowColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
