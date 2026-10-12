import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// Müşteri Randevu Detay Sayfası
/// Geçmiş randevulara yorum ve puan verme
class CustomerAppointmentDetailPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const CustomerAppointmentDetailPage({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
  });

  @override
  State<CustomerAppointmentDetailPage> createState() =>
      _CustomerAppointmentDetailPageState();
}

class _CustomerAppointmentDetailPageState
    extends State<CustomerAppointmentDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  bool _hasExistingReview = false;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Varolan yorumu yükle
  Future<void> _loadExistingReview() async {
    final comment = widget.appointmentData['comment'] as String?;
    final rating = widget.appointmentData['rating'] as int?;

    if (comment != null && comment.isNotEmpty) {
      setState(() {
        _commentController.text = comment;
        _rating = rating ?? 0;
        _hasExistingReview = true;
      });
    }
  }

  /// Yorum ve puanı kaydet
  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showSnackBar('Lütfen puan verin', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'comment': _commentController.text.trim(),
        'rating': _rating,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Yorumunuz kaydedildi. Teşekkürler!');
      
      // 1 saniye sonra geri dön
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF00FF88),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = (widget.appointmentData['date'] as Timestamp?)?.toDate();
    final time = widget.appointmentData['time'] as String? ?? '';
    final status = widget.appointmentData['status'] as String? ?? '';
    final barberId = widget.appointmentData['barberId'] as String? ?? '';

    final dateTime = date != null
        ? DateTime(date.year, date.month, date.day)
        : DateTime.now();

    final formattedDate = DateFormat('dd MMMM yyyy', 'tr_TR').format(dateTime);

    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Randevu Detayı',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Randevu Bilgileri Kartı
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(status).withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // İkon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(status),
                            _getStatusColor(status).withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(status).withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarih
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Saat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF00D4FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Durum badge
                    _buildStatusBadge(status),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),

              const SizedBox(height: 32),

              // Sadece tamamlanmış randevulara yorum izni
              if (status == 'completed') ...[
                // Puan verme başlığı
                Text(
                  'Hizmet Puanı',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

                const SizedBox(height: 16),

                // Yıldız puanlama
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _rating = starValue;
                                });
                              },
                        icon: Icon(
                          starValue <= _rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: starValue <= _rating
                              ? const Color(0xFFFFD700)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      ).shimmer(
                        delay: Duration(milliseconds: index * 100),
                        duration: const Duration(seconds: 2),
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                      );
                    }),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

                const SizedBox(height: 24),

                // Yorum başlığı
                Text(
                  'Yorumunuz',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

                const SizedBox(height: 16),

                // Yorum alanı
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    enabled: !_isSubmitting,
                    maxLines: 5,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Deneyiminizi paylaşın...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

                const SizedBox(height: 24),

                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 8),
                              Text(
                                _hasExistingReview
                                    ? 'Yorumu Güncelle'
                                    : 'Yorumu Kaydet',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideY(begin: 0.1),
              ] else ...[
                // İptal edilmiş randevu için mesaj
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sadece tamamlanmış randevulara yorum yapabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = const Color(0xFF00FF88);
        label = 'Tamamlandı';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.redAccent;
        label = 'İptal Edildi';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF00FF88);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
