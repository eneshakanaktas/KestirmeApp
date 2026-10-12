import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'customer_appointments_page.dart';
import 'barber_active_appointments_page.dart';

/// Ultra Premium Bildirim Listesi Sayfası
class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmanız gerekiyor')));
    }

    final notificationService = NotificationService();
    // Mark as read when opening
    notificationService.markAllAsRead(user.uid);

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
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tümünü Sil',
              onPressed: () => _showDeleteAllDialog(context, user.uid, notificationService),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: notificationService.getUserNotifications(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }
            
            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
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
                      child: Icon(Icons.notifications_none, size: 64, color: Colors.white.withOpacity(0.3)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bildiriminiz yok',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                  ],
                ).animate().fadeIn().scale(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final notification = doc.data() as Map<String, dynamic>;
                final timestamp = (notification['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                
                return Dismissible(
                  key: Key(doc.id),
                  onDismissed: (_) {
                    notificationService.deleteNotification(doc.id);
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Color(0xFFFF4757)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleNotificationTap(context, notification),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00D4FF).withOpacity(0.1),
                          ),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.2),
                               blurRadius: 10,
                             ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.3), blurRadius: 8),
                                ],
                              ),
                              child: const Icon(Icons.notifications, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['title'] ?? 'Bildirim',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['body'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(timestamp),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, String userId, NotificationService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 12),
            const Text('Tüm Bildirimleri Sil', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Tüm bildirimlerinizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
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
              await service.deleteAllNotifications(userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tüm bildirimler silindi'),
                    backgroundColor: Color(0xFF00FF88),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
            ),
            child: const Text('Tümünü Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Bildirime tıklandığında ilgili sayfaya yönlendir
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final role = notification['role'] as String?;
    
    if (role == 'barber') {
      // Berber için Randevu Talepleri sayfasına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BarberActiveAppointmentsPage(),
        ),
      );
    } else if (role == 'customer') {
      // Müşteri için Randevularım sayfasına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerAppointmentsPage(),
        ),
      );
    }
  }
}
