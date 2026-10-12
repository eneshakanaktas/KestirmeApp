import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Bildirim işlemlerini yöneten servis
/// Kullanıcı bildirimlerini Firestore'da yönetir
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Bildirim oluştur
  /// 
  /// [userId] Bildirimi alacak kullanıcının uid'si
  /// [role] Kullanıcı rolü (customer / barber)
  /// [type] Bildirim tipi (created / approved / cancelled / completed)
  /// [message] Kullanıcıya gösterilecek mesaj
  /// [appointmentId] İlgili randevu ID'si
  /// 
  /// Idempotent: Aynı appointmentId + type için tekrar bildirim oluşturmaz
  Future<void> createNotification({
    required String userId,
    required String role,
    required String type,
    required String message,
    required String appointmentId,
  }) async {
    try {
      // Idempotent check: Aynı randevu + type için bildirim var mı?
      final existing = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('appointmentId', isEqualTo: appointmentId)
          .where('type', isEqualTo: type)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('Notification already exists: $type for appointment $appointmentId');
        return; // Duplicate, oluşturma
      }

      // Yeni bildirim oluştur - title ve body formatında
      await _notificationsCollection.add({
        'userId': userId,
        'role': role,
        'type': type,
        'title': _getNotificationTitle(type),
        'body': message,
        'appointmentId': appointmentId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification created: $type for user $userId');
    } catch (e) {
      debugPrint('Bildirim oluşturma hatası: $e');
      // Fail silently - don't break the main flow
    }
  }

  /// Kullanıcının bildirimlerini dinle (real-time)
  /// En yeni bildirimler üstte
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Okunmamış bildirim sayısı (real-time)
  Stream<int> getUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Okunmamış bildirim sayısı stream'i (alias for getUnreadCount)
  Stream<int> getUnreadCountStream(String userId) {
    return getUnreadCount(userId);
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Bildirim işaretleme hatası: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadDocs = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('All notifications marked as read for user $userId');
    } catch (e) {
      debugPrint('Toplu bildirim işaretleme hatası: $e');
    }
  }

  /// Kullanıcının tüm bildirimlerini sil (batch delete)
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final allDocs = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      if (allDocs.docs.isEmpty) {
        debugPrint('No notifications to delete for user $userId');
        return;
      }

      final batch = _firestore.batch();
      for (var doc in allDocs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('All notifications deleted for user $userId (${allDocs.docs.length} items)');
    } catch (e) {
      debugPrint('Toplu bildirim silme hatası: $e');
    }
  }

  /// Bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      debugPrint('Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Bildirim silme hatası: $e');
    }
  }

  /// Bildirim tipine göre başlık oluştur
  String _getNotificationTitle(String type) {
    switch (type) {
      case 'created':
        return '📅 Yeni Randevu';
      case 'approved':
        return '✅ Randevu Onaylandı';
      case 'cancelled':
        return '❌ Randevu İptal Edildi';
      case 'completed':
        return '✨ Randevu Tamamlandı';
      default:
        return '🔔 Bildirim';
    }
  }
}
