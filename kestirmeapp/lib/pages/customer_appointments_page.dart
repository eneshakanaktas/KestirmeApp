import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/appointment_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/premium_countdown_timer.dart';

/// Ultra Premium Müşteri Randevuları Sayfası
class CustomerAppointmentsPage extends StatefulWidget {
  const CustomerAppointmentsPage({super.key});

  @override
  State<CustomerAppointmentsPage> createState() => _CustomerAppointmentsPageState();
}

class _CustomerAppointmentsPageState extends State<CustomerAppointmentsPage> with AutomaticKeepAliveClientMixin {
  final AppointmentService _appointmentService = AppointmentService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                    colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Randevularım',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _appointmentService.getCustomerAppointments(user.uid),
          builder: (context, snapshot) {
            // Optimize: Only show loading on initial load, not on updates
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('Hata oluştu', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_busy,
                        size: 64,
                        color: const Color(0xFF00D4FF).withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Henüz randevunuz yok',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni randevu almak için ana sayfaya dönün',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              );
            }

            final appointments = snapshot.data!.docs;
            
            // Geçmiş randevuları filtrele - sadece gelecek veya bugünkü randevuları göster
            final now = DateTime.now();
            final futureAppointments = appointments.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              final time = data['time'] as String? ?? '00:00';
              
              if (date == null) return false;
              
              final timeParts = time.split(':');
              final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
              final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
              final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
              
              // Randevu şu andan sonraysa göster
              return dateTime.isAfter(now);
            }).toList();
            
            // Geçmiş randevu varsa ve gelecek randevu yoksa bilgi mesajı göster
            if (futureAppointments.isEmpty && appointments.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        size: 64,
                        color: const Color(0xFF00D4FF).withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aktif randevunuz yok',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Geçmiş randevularınız için "Geçmiş" sekmesine bakabilirsiniz',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: futureAppointments.length,
              itemBuilder: (context, index) {
                final doc = futureAppointments[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                final time = data['time'] as String? ?? '00:00';
                final timeParts = time.split(':');
                final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
                final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
                final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
                final status = data['status'] as String;
                final barberId = data['barberId'] as String;
                final remaining = dateTime.difference(DateTime.now());

                return KeyedSubtree(
                  key: ValueKey(docId),
                  child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('barbers').doc(barberId).get(),
                  builder: (context, barberSnapshot) {
                    final barberData = barberSnapshot.data?.data() as Map<String, dynamic>?;
                    final salonName = barberData?['salonName'] as String? ?? 'Berber';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getStatusColor(status),
                                        _getStatusColor(status).withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor(status).withOpacity(0.4),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.content_cut,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salonName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                ),
                                // Premium Countdown Timer
                                if (status == 'approved' && !remaining.isNegative)
                                  PremiumCountdownTimer(
                                    targetDateTime: dateTime,
                                    showTitle: false,
                                    size: 80,
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Date & Time
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.calendar_today,
                                    label: 'Tarih',
                                    value: '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.access_time,
                                    label: 'Saat',
                                    value: '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                                  ),
                                ],
                              ),
                            ),
                            
                            // Cancel Button
                            if (status == 'pending' || status == 'approved')
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showCancelDialog(context, docId),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('RANDEVUYU İPTAL ET'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFF4757),
                                      side: const BorderSide(color: Color(0xFFFF4757)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * index))
                      .slideX(begin: 0.1);
                  },
                ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCountdownCircle(Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    
    Color color;
    if (remaining.inMinutes < 30) {
      color = const Color(0xFFFF4757);
    } else if (remaining.inHours < 2) {
      color = const Color(0xFFFFD700);
    } else {
      color = const Color(0xFF00FF88);
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hours > 0 ? '${hours}s' : minutes > 0 ? '${minutes}d' : '${seconds}s',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hours > 0)
              Text(
                '${minutes}d',
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFD700);
      case 'approved':
        return const Color(0xFF00FF88);
      case 'completed':
        return const Color(0xFF00D4FF);
      case 'cancelled':
        return const Color(0xFFFF4757);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'approved':
        return 'Onaylandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  void _showCancelDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Randevuyu İptal Et', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu randevuyu iptal etmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              _appointmentService.updateAppointmentStatus(
                appointmentId: docId,
                newStatus: 'cancelled',
                requestedBy: 'customer',
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
            ),
            child: const Text('İptal Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
