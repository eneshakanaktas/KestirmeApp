import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Randevu Defteri Sayfası
class BarberAppointmentBookPage extends StatefulWidget {
  const BarberAppointmentBookPage({super.key});

  @override
  State<BarberAppointmentBookPage> createState() => _BarberAppointmentBookPageState();
}

class _BarberAppointmentBookPageState extends State<BarberAppointmentBookPage> {
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
                child: const Icon(Icons.book, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Randevu Defteri', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _appointmentService.getBarberAppointments(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final appointments = snapshot.data!.docs;

            // Filtreleme ve Gruplandırma
            final filteredAppointments = appointments.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? '';
              final date = (data['date'] as Timestamp?)?.toDate();
              
              if (status != 'approved' && status != 'completed') return false;
              
              if (date != null) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final appointmentDay = DateTime(date.year, date.month, date.day);
                return appointmentDay.isAtSameMomentAs(today) || appointmentDay.isAfter(today);
              }
              return false;
            }).toList();

            if (filteredAppointments.isEmpty) {
               return _buildEmptyState();
            }

            // Group by Date
            final Map<String, List<QueryDocumentSnapshot>> groupedByDate = {};
            for (var doc in filteredAppointments) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              if (date != null) {
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                if (!groupedByDate.containsKey(dateKey)) {
                  groupedByDate[dateKey] = [];
                }
                groupedByDate[dateKey]!.add(doc);
              }
            }

            final sortedDates = groupedByDate.keys.toList()..sort();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final dateAppointments = groupedByDate[dateKey]!;
                
                // Sort by time
                dateAppointments.sort((a, b) {
                  final timeA = (a.data() as Map<String, dynamic>)['time'] as String? ?? '';
                  final timeB = (b.data() as Map<String, dynamic>)['time'] as String? ?? '';
                  return timeA.compareTo(timeB);
                });

                final firstDoc = dateAppointments.first;
                final displayDate = ((firstDoc.data() as Map<String, dynamic>)['date'] as Timestamp).toDate();

                return _buildDayCard(displayDate, dateAppointments, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCard(DateTime date, List<QueryDocumentSnapshot> appointments, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(date).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE', 'tr_TR').format(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${appointments.length} Randevu',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
            itemBuilder: (context, i) {
              final data = appointments[i].data() as Map<String, dynamic>;
              return _buildAppointmentItem(data);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
  }

  Widget _buildAppointmentItem(Map<String, dynamic> data) {
    final time = data['time'] as String? ?? '';
    final customerName = data['customerName'] as String? ?? 'Misafir';
    final customerPhone = data['customerPhone'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Text(
          time,
          style: const TextStyle(
            color: Color(0xFF00D4FF),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        customerName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: customerPhone.isNotEmpty 
          ? Row(
              children: [
                Icon(Icons.phone, size: 12, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  customerPhone,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ) 
          : null,
      trailing: _buildStatusBadge(status),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isCompleted = status == 'completed';
    final color = isCompleted ? const Color(0xFF00D4FF) : const Color(0xFF00FF88);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        isCompleted ? 'Tamamlandı' : 'Onaylı',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(Icons.event_note, size: 64, color: Colors.white.withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          Text(
            'Randevu defteri boş',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
