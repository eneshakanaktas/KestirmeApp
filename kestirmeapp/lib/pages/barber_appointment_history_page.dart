import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Berber Randevu Geçmişi Sayfası
class BarberAppointmentHistoryPage extends StatefulWidget {
  const BarberAppointmentHistoryPage({super.key});

  @override
  State<BarberAppointmentHistoryPage> createState() => _BarberAppointmentHistoryPageState();
}

class _BarberAppointmentHistoryPageState extends State<BarberAppointmentHistoryPage> {

  final AppointmentService _appointmentService = AppointmentService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmanız gerekiyor')));
    }

    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Geçmiş Randevular', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _appointmentService.getBarberHistoryAppointments(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_toggle_off, size: 60, color: const Color(0xFFFFD700).withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Geçmiş randevu bulunamadı',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                  ],
                ).animate().fadeIn().scale(),
              );
            }

            final appointments = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final doc = appointments[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                final time = data['time'] as String? ?? '00:00';
                final timeParts = time.split(':');
                final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
                final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
                final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
                final customerName = data['customerName'] ?? 'Müşteri';
                final status = data['status'] as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Status Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(dateTime),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                          ),
                          child: Text(
                            status == 'completed' ? 'Tamamlandı' : 'İptal',
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4757)),
                          onPressed: () => _showDeleteDialog(context, docId),
                          tooltip: 'Sil',
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return status == 'completed' ? const Color(0xFF00D4FF) : const Color(0xFFFF4757);
  }

  IconData _getStatusIcon(String status) {
    return status == 'completed' ? Icons.check_circle_outline : Icons.cancel_outlined;
  }

  void _showDeleteDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4757), size: 28),
            SizedBox(width: 12),
            Text('Randevuyu Sil', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Bu randevuyu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _appointmentService.deleteAppointment(appointmentId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Randevu silindi'),
                      backgroundColor: Color(0xFF00FF88),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Color(0xFFFF4757),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
