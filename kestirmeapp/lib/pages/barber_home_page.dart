import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate_page.dart';
import 'barber_active_appointments_page.dart';
import 'barber_appointment_history_page.dart';
import 'barber_edit_profile_page.dart';
import 'barber_detail_page.dart';
import 'notification_list_page.dart';
import 'barber_appointment_book_page.dart';
import '../services/notification_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Berber Ana Sayfası
class BarberHomePage extends StatelessWidget {
  const BarberHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(Icons.content_cut, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Berber Paneli',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          actions: [
            // Notifications
            if (user != null)
              StreamBuilder<int>(
                stream: NotificationService().getUnreadCount(user.uid),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationListPage()),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF4757), Color(0xFFFF6B6B)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.book_outlined),
              tooltip: 'Berber Defteri',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarberAppointmentBookPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.lock_reset),
              tooltip: 'Şifre Değiştir',
              onPressed: () => Navigator.pushNamed(context, '/change-password'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Çıkış',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthGatePage()),
                  );
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════
              // WELCOME HEADER
              // ═══════════════════════════════════════════════════
              if (user != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('barbers').doc(user.uid).get(),
                  builder: (context, snapshot) {
                    final salonName = snapshot.data?.get('salonName') ?? 'Salon';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFD700).withOpacity(0.2),
                            const Color(0xFFFF8C00).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş Geldiniz',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            salonName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2);
                  },
                ),
              
              const SizedBox(height: 32),
              
              // ═══════════════════════════════════════════════════
              // QUICK ACTIONS GRID
              // ═══════════════════════════════════════════════════
              Text(
                'HIZLI ERİŞİM',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildActionCard(
                    icon: Icons.pending_actions,
                    title: 'Bekleyen\nRandevular',
                    gradient: const [Color(0xFF00D4FF), Color(0xFF00FF88)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BarberActiveAppointmentsPage()),
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                  
                  _buildActionCard(
                    icon: Icons.history,
                    title: 'Geçmiş\nRandevular',
                    gradient: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BarberAppointmentHistoryPage()),
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                  
                  _buildActionCard(
                    icon: Icons.edit,
                    title: 'Profil\nDüzenle',
                    gradient: const [Color(0xFFFF6B35), Color(0xFFFF4757)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BarberEditProfilePage()),
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.8, 0.8)),
                  
                  _buildActionCard(
                    icon: Icons.store,
                    title: 'Salon\nBilgileri',
                    gradient: const [Color(0xFF9B59B6), Color(0xFFE91E63)],
                    onTap: () {
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BarberDetailPage(
                              barberId: user.uid,
                              salonName: 'Salonum',
                            ),
                          ),
                        );
                      }
                    },
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // ═══════════════════════════════════════════════════
              // TODAY'S APPOINTMENTS
              // ═══════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "BUGÜNKÜ RANDEVULAR",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BarberActiveAppointmentsPage()),
                    ),
                    child: const Text(
                      'Tümünü Gör',
                      style: TextStyle(color: Color(0xFF00D4FF)),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
              
              const SizedBox(height: 12),
              
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('barberId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'approved')
                      .orderBy('dateTime')
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Bugün randevu yok',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final dateTime = (data['dateTime'] as Timestamp).toDate();
                        final customerName = data['customerName'] ?? 'Müşteri';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF00D4FF).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D4FF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.schedule,
                                  color: Color(0xFF00D4FF),
                                  size: 24,
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: const Color(0xFF00D4FF),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF88).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Onaylı',
                                  style: TextStyle(
                                    color: Color(0xFF00FF88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideX(begin: 0.1);
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: gradient[0].withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
