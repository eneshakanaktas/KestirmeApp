import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:async';

/// Ultra Premium Dairesel Countdown Timer Widget
/// Turkuaz dolum efekti, altın rakamlar, animasyonlu
class PremiumCountdownTimer extends StatefulWidget {
  final DateTime targetDateTime;
  final bool showTitle;
  final double size;

  const PremiumCountdownTimer({
    super.key,
    required this.targetDateTime,
    this.showTitle = true,
    this.size = 140,
  });

  @override
  State<PremiumCountdownTimer> createState() => _PremiumCountdownTimerState();
}

class _PremiumCountdownTimerState extends State<PremiumCountdownTimer> {
  late Timer _timer;
  Duration remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    remaining = widget.targetDateTime.difference(now);
    if (remaining.isNegative) {
      remaining = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    
    // Renk duruma göre değişsin
    Color progressColor;
    Color textColor;
    
    if (remaining.inMinutes < 30) {
      progressColor = const Color(0xFFFF4757); // Kırmızı - acil
      textColor = const Color(0xFFFFD700); // Altın
    } else if (remaining.inHours < 2) {
      progressColor = const Color(0xFFFFD700); // Altın - yaklaşıyor
      textColor = const Color(0xFFFFD700);
    } else {
      progressColor = const Color(0xFF00D4FF); // Turkuaz - rahat
      textColor = const Color(0xFFFFD700);
    }

    // Progress değeri (24 saat = tam daire)
    final totalMinutes = remaining.inMinutes;
    final maxMinutes = 24 * 60; // 24 saat
    final progress = (totalMinutes / maxMinutes).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Randevuya Kalan Süre',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: const Duration(seconds: 2),
                color: progressColor.withOpacity(0.3),
              ),
          ),
        
        // Dairesel Progress Bar
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: progressColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arka plan daire (koyu)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
              ),
              
              // Animasyonlu progress circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: progress,
                    color: progressColor,
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: const Duration(seconds: 3),
                  color: progressColor.withOpacity(0.2),
                ),
              
              // İçerik (rakamlar)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ana süre göstergesi
                  Text(
                    hours > 0 
                        ? '${hours}s'
                        : minutes > 0 
                            ? '${minutes}d'
                            : '${seconds}s',
                    style: TextStyle(
                      color: textColor,
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: textColor.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: Colors.white.withOpacity(0.3),
                    ),
                  
                  // Alt süre göstergesi
                  if (hours > 0)
                    Text(
                      '${minutes}d',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: widget.size * 0.12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  
                  if (hours > 0 || minutes > 0)
                    const SizedBox(height: 2),
                  
                  if (hours > 0 || minutes > 0)
                    Text(
                      '${seconds}s',
                      style: TextStyle(
                        color: textColor.withOpacity(0.4),
                        fontSize: widget.size * 0.1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
          ),
      ],
    );
  }
}

/// Custom painter için dairesel progress çizer
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    // Progress çemberi
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Gradient efekti için
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.3),
          color,
          color,
          color.withOpacity(0.3),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Çemberi çiz (üstten başlasın)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Glow efekti ekle
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
