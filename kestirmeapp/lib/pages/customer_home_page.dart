import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate_page.dart';
import 'customer_create_appointment_page.dart';
import 'customer_appointments_page.dart';
import 'customer_appointment_history_page.dart';
import 'notification_list_page.dart';
import 'barber_detail_page.dart';
import 'ai_chat_page.dart';
import 'salon_map_page.dart';
import '../services/barber_service.dart';
import '../services/notification_service.dart';
import '../utils/salon_name_helper.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Customer Home Page
class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final barberService = BarberService();

    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animasyonlu makas ikonu
              const Icon(
                Icons.content_cut,
                color: Color(0xFFFFD700),
                size: 24,
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                .rotate(
                  begin: -0.05,
                  end: 0.05,
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                ),
              const SizedBox(width: 12),
              // Premium "Berberler" yazısı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.1),
                      const Color(0xFFFF8C00).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ).createShader(bounds),
                  child: const Text(
                    'Berberler',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 3),
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
              ),
            ],
          ),
          actions: [
             if (user != null)
              StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(user.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListPage())),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              _buildAppBarIcon(context, Icons.map_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalonMapPage()))),
              _buildAppBarIcon(context, Icons.event_note, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerAppointmentsPage()))),
              _buildAppBarIcon(context, Icons.history, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerAppointmentHistoryPage()))),
              _buildAppBarIcon(context, Icons.lock_reset, () => Navigator.pushNamed(context, '/change-password')),
              _buildAppBarIcon(context, Icons.logout, () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGatePage()));
              }),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: barberService.getActiveBarbers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Hata oluştu', style: TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_outlined, size: 64, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('Aktif berber yok', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              );
            }

            final barbers = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                final barberData = barbers[index].data() as Map<String, dynamic>;
                final barberId = barbers[index].id;
                final salonName = SalonNameHelper.getSalonName(
                  email: barberData['email'] as String?,
                  firestoreSalonName: barberData['salonName'] as String?,
                );

                return _buildBarberCard(context, barberId, salonName, barberData);
              },
            );
          },
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF00FF88)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
               BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatPage())),
            label: const Text('Asistan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarIcon(BuildContext context, IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    );
  }

  Widget _buildBarberCard(BuildContext context, String barberId, String salonName, Map<String, dynamic> data) {
    final phone = data['phone'] as String?;
    final address = data['address'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BarberDetailPage(barberId: barberId, salonName: salonName),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF00FF88)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.content_cut, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salonName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Profesyonel Hizmet',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
                  ],
                ),
                if (phone != null || address != null) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  if (phone != null)
                    _buildInfoRow(Icons.phone, phone),
                  if (address != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, address),
                  ],
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                         builder: (_) => CustomerCreateAppointmentPage(barberId: barberId),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: const Color(0xFF00D4FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFF00D4FF).withOpacity(0.5)),
                      ),
                    ),
                    child: const Text('Randevu Al', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
