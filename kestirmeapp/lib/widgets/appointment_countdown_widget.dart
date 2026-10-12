import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Randevu geri sayım widget'ı
/// Bir sonraki randevuya kalan süreyi gösterir
/// Belirli eşiklerde bildirim ve titreşim tetikler
class AppointmentCountdownWidget extends StatefulWidget {
  final DateTime appointmentDateTime;

  const AppointmentCountdownWidget({
    super.key,
    required this.appointmentDateTime,
  });

  @override
  State<AppointmentCountdownWidget> createState() =>
      _AppointmentCountdownWidgetState();
}

class _AppointmentCountdownWidgetState
    extends State<AppointmentCountdownWidget> {
  Timer? _timer;
  Duration? _remainingTime;

  // Bildirim bayrakları - tekrar etmeyi önler
  bool _notified30Min = false;
  bool _notified5Min = false;
  bool _notifiedTimeUp = false;
  
  // İlk threshold check yapıldı mı
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
    
    // Context-dependent işlemleri ilk frame'den sonra yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performInitialThresholdCheck();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// İlk threshold kontrolü (context-safe)
  void _performInitialThresholdCheck() {
    if (_remainingTime != null && !_initialCheckDone) {
      _initialCheckDone = true;
      _checkThresholds(_remainingTime!);
    }
  }

  /// Kalan süreyi hesapla
  void _calculateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.appointmentDateTime.difference(now);

    setState(() {
      _remainingTime = difference;
    });
  }

  /// Eşikleri kontrol et ve bildirim tetikle
  void _checkThresholds(Duration remaining) {
    // Context yoksa çık
    if (!mounted) return;
    
    final totalMinutes = remaining.inMinutes;

    // 30 dakika öncesi
    if (!_notified30Min && totalMinutes <= 30 && totalMinutes > 29) {
      _notified30Min = true;
      _triggerNotification(
        '30 Dakika Kaldı',
        'Randevunuza 30 dakika kaldı!',
        isLight: true,
      );
    }

    // 5 dakika öncesi
    if (!_notified5Min && totalMinutes <= 5 && totalMinutes > 4) {
      _notified5Min = true;
      _triggerNotification(
        '5 Dakika Kaldı',
        'Randevunuza 5 dakika kaldı! Hazırlıklı olun.',
        isLight: false,
      );
    }

    // Randevu zamanı geldi
    if (!_notifiedTimeUp && remaining.isNegative) {
      _notifiedTimeUp = true;
      _triggerNotification(
        'Randevu Zamanı!',
        'Randevunuzun zamanı geldi!',
        isLight: false,
      );
    }
  }

  /// Bildirim ve titreşim tetikle
  void _triggerNotification(String title, String message, {required bool isLight}) {
    if (!mounted) return;

    // Snackbar ile bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? Colors.orange : Colors.red,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // Haptic feedback (titreşim)
    try {
      if (isLight) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Haptic feedback hatası (göz ardı edildi): $e');
    }
  }

  /// Timer'ı başlat (her saniye güncelle)
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateRemainingTime();
        
        // Sadece ilk check yapıldıysa threshold kontrolü yap
        if (_initialCheckDone && _remainingTime != null) {
          _checkThresholds(_remainingTime!);
        }
      }
    });
  }

  /// Süreyi formatla (gün, saat, dakika, saniye)
  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      // Geçmiş randevu için formatla
      final absDuration = duration.abs();
      final days = absDuration.inDays;
      final hours = absDuration.inHours.remainder(24);
      final minutes = absDuration.inMinutes.remainder(60);

      if (days > 0) {
        return '$days gün önce geçti';
      } else if (hours > 0) {
        return '$hours saat önce geçti';
      } else if (minutes > 0) {
        return '$minutes dakika önce geçti';
      } else {
        return 'Randevu zamanı geldi';
      }
    }

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];

    if (days > 0) {
      parts.add('$days gün');
    }
    if (hours > 0) {
      parts.add('$hours saat');
    }
    if (minutes > 0) {
      parts.add('$minutes dakika');
    }
    if (seconds > 0) {
      parts.add('$seconds saniye');
    }

    return parts.isEmpty ? 'Randevu zamanı geldi' : parts.join(' ');
  }

  /// Kalan süreye göre renk döndür
  /// 🔴 Kırmızı: 1 saatten az
  /// 🟠 Turuncu: 1-3 saat arası
  /// 🟢 Yeşil: 3 saatten fazla
  /// ⚫ Gri: Geçmiş randevular
  Color _getTimeBasedColor(BuildContext context, Duration remaining) {
    final colorScheme = Theme.of(context).colorScheme;

    if (remaining.isNegative) {
      return Colors.grey;
    }

    final totalMinutes = remaining.inMinutes;

    if (totalMinutes < 60) {
      // 1 saatten az - Kırmızı (acil)
      return Colors.red;
    } else if (totalMinutes < 180) {
      // 1-3 saat arası - Turuncu (yaklaşıyor)
      return Colors.orange;
    } else {
      // 3+ saat - Yeşil (rahat)
      return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_remainingTime == null) {
      return const SizedBox.shrink();
    }

    final isTimeUp = _remainingTime!.isNegative;
    final formattedTime = _formatDuration(_remainingTime!);
    final timeColor = _getTimeBasedColor(context, _remainingTime!);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: timeColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTimeUp ? Icons.history : Icons.timer_outlined,
            size: 22,
            color: timeColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTimeUp ? 'Geçen Süre' : 'Kalan Süre',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: timeColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: timeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
