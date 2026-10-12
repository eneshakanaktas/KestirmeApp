import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'customer_appointment_detail_page.dart';

/// Ultra Premium Customer Appointment History Page
class CustomerAppointmentHistoryPage extends StatefulWidget {
  const CustomerAppointmentHistoryPage({super.key});

  @override
  State<CustomerAppointmentHistoryPage> createState() =>
      _CustomerAppointmentHistoryPageState();
}

class _CustomerAppointmentHistoryPageState
    extends State<CustomerAppointmentHistoryPage> {
  final AppointmentService _appointmentService = AppointmentService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmanız gerekli')));
    }

    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Randevu Geçmişi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _appointmentService.getCustomerHistoryAppointments(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history,
                          size: 64, color: Colors.white.withOpacity(0.3)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Geçmiş randevu bulunmuyor',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 16),
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
                
                // Parse date
                final date = (data['date'] as Timestamp?)?.toDate();
                final time = data['time'] as String? ?? '';
                final status = data['status'] as String? ?? '';
                
                final dateTime = date != null 
                    ? DateTime(date.year, date.month, date.day) 
                    : DateTime.now();
                
                final formattedDate = DateFormat('dd MMMM yyyy', 'tr_TR').format(dateTime);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    onTap: () {
                      // Navigate to detail page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerAppointmentDetailPage(
                            appointmentId: doc.id,
                            appointmentData: data,
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        status == 'completed' ? Icons.check_circle : Icons.cancel,
                        color: status == 'completed'
                            ? const Color(0xFF00FF88)
                            : Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      formattedDate,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4757)),
                      onPressed: () => _showDeleteDialog(context, doc.id),
                      tooltip: 'Sil',
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = const Color(0xFF00FF88);
        label = 'Tamamlandı';
        icon = Icons.check;
        break;
      case 'cancelled':
        color = Colors.redAccent;
        label = 'İptal Edildi';
        icon = Icons.close;
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Silme onay dialogu gösterir
  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Randevuyu Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu randevuyu geçmişten silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _appointmentService.deleteAppointment(docId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Randevu silindi'),
                      backgroundColor: Color(0xFF00FF88),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Color(0xFFFF4757),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
            ),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
