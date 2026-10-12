import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/appointment_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../widgets/premium_countdown_timer.dart';

/// Ultra Premium Berber Aktif Randevular Sayfası
class BarberActiveAppointmentsPage extends StatefulWidget {
  const BarberActiveAppointmentsPage({super.key});

  @override
  State<BarberActiveAppointmentsPage> createState() => _BarberActiveAppointmentsPageState();
}

class _BarberActiveAppointmentsPageState extends State<BarberActiveAppointmentsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmanız gerekiyor')));
    }

    final appointmentService = AppointmentService();

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
                child: const Icon(Icons.pending_actions, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Randevu Talepleri', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: appointmentService.getBarberAppointments(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildEmptyState(
                icon: Icons.error_outline,
                title: 'Bir hata oluştu',
                color: Colors.red,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            
            // Geçmiş randevuları filtrele
            final now = DateTime.now();
            final futureDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              final time = data['time'] as String? ?? '00:00';
              
              if (date == null) return false;
              
              final timeParts = time.split(':');
              final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
              final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
              final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
              
              return dateTime.isAfter(now);
            }).toList();
            
            final pendingDocs = futureDocs.where((d) => (d.data() as Map)['status'] == 'pending').toList();
            final approvedDocs = futureDocs.where((d) => (d.data() as Map)['status'] == 'approved').toList();

            if (pendingDocs.isEmpty && approvedDocs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.event_available,
                title: 'Bekleyen randevu yok',
                color: const Color(0xFFFFD700),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // PENDING SECTION
                if (pendingDocs.isNotEmpty) ...[
                  _buildSectionHeader('BEKLEYENler', pendingDocs.length, const Color(0xFFFFD700)),
                  const SizedBox(height: 12),
                  ...pendingDocs.asMap().entries.map((entry) => 
                    _buildAppointmentCard(context, entry.value, appointmentService, entry.key, true)
                  ),
                  const SizedBox(height: 24),
                ],
                
                // APPROVED SECTION
                if (approvedDocs.isNotEmpty) ...[
                  _buildSectionHeader('ONAYLANANLAR', approvedDocs.length, const Color(0xFF00FF88)),
                  const SizedBox(height: 12),
                  ...approvedDocs.asMap().entries.map((entry) => 
                    _buildAppointmentCard(context, entry.value, appointmentService, entry.key, false)
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color, blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    DocumentSnapshot doc,
    AppointmentService service,
    int index,
    bool isPending,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final time = data['time'] as String? ?? '00:00';
    final timeParts = time.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
    final customerName = data['customerName'] ?? 'Müşteri';
    final customerPhone = data['customerPhone'] ?? '-';
    final status = data['status'] as String;

    return KeyedSubtree(
      key: ValueKey(doc.id),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isPending ? const Color(0xFFFFD700) : const Color(0xFF00FF88)).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isPending ? const Color(0xFFFFD700) : const Color(0xFF00FF88)).withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPending
                          ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                          : [const Color(0xFF00FF88), const Color(0xFF00D4FF)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (isPending ? const Color(0xFFFFD700) : const Color(0xFF00FF88)).withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      customerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(
                            customerPhone,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date Time Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF00D4FF), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF00D4FF), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Premium Countdown Timer (sadece onaylanmış randevular için)
            if (status == 'approved') ...[
              const SizedBox(height: 20),
              Center(
                child: PremiumCountdownTimer(
                  targetDateTime: dateTime,
                  showTitle: true,
                  size: 120,
                ),
              ),
            ],
            
            // Action Buttons
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'REDDET',
                      color: const Color(0xFFFF4757),
                      icon: Icons.close,
                      onTap: () => service.updateAppointmentStatus(
                        appointmentId: doc.id,
                        newStatus: 'cancelled',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: 'ONAYLA',
                      color: const Color(0xFF00FF88),
                      icon: Icons.check,
                      filled: true,
                      onTap: () => service.updateAppointmentStatus(
                        appointmentId: doc.id,
                        newStatus: 'approved',
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  label: 'TAMAMLANDI OLARAK İŞARETLE',
                  color: const Color(0xFF00D4FF),
                  icon: Icons.check_circle,
                  filled: true,
                  onTap: () => service.updateAppointmentStatus(
                    appointmentId: doc.id,
                    newStatus: 'completed',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index))
      .slideY(begin: 0.1),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    if (filled) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'pending' 
        ? const Color(0xFFFFD700) 
        : status == 'approved' 
            ? const Color(0xFF00FF88) 
            : Colors.grey;
    final text = status == 'pending' ? 'Bekliyor' : status == 'approved' ? 'Onaylı' : status;
    
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required Color color}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
