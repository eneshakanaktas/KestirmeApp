import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Randevu işlemlerini yöneten servis
/// Firestore'da appointments collection'ı üzerinde CRUD operasyonları yapar
class AppointmentService {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService(); // STEP 15
  
  // Appointments collection referansı
  CollectionReference get _appointmentsCollection =>
      _firestore.collection('appointments');

  /// Yeni randevu oluşturur
  /// 
  /// [customerId] Randevuyu oluşturan müşterinin uid'si
  /// [barberId] Randevunun yapılacağı berberin uid'si
  /// [date] Randevu tarihi
  /// [time] Randevu saati (String formatında, örn: "14:30")
  /// [customerName] Müşteri isim-soyisim
  /// [customerPhone] Müşteri telefon numarası (+90 ile başlayan)
  /// 
  /// Throws: Exception if there's a booking conflict or time validation fails
  Future<void> createAppointment({
    required String customerId,
    required String barberId,
    required DateTime date,
    required String time,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      // STEP 14: Past date/time validation (with +2 min tolerance)
      final appointmentDateTime = _combineDateTime(date, time);
      final now = DateTime.now();
      final tolerance = const Duration(minutes: 2); // Kullanıcı bulunduğu dakikada randevu alabilsin
      
      if (appointmentDateTime.isBefore(now.subtract(tolerance))) {
        throw Exception('Geçmiş tarih veya saat için randevu oluşturulamaz.');
      }

      // STEP 12: Double booking prevention - conflict check
      final hasConflict = await _checkConflict(
        barberId: barberId,
        date: date,
        time: time,
      );

      if (hasConflict) {
        throw Exception('Bu saat için randevu dolu. Lütfen başka bir saat seçin.');
      }


      // Firestore'a randevu kaydı oluştur
      final appointmentRef = await _appointmentsCollection.add({
        'customerId': customerId,
        'barberId': barberId,
        'date': Timestamp.fromDate(date),
        'time': time,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final appointmentId = appointmentRef.id;
      debugPrint('Randevu başarıyla oluşturuldu: $date $time');

      // Randevu tarihi formatla (güzelformat için)
      final formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';

      // STEP 15: Müşteriye bildirim gönder
      await _notificationService.createNotification(
        userId: customerId,
        role: 'customer',
        type: 'created',
        message: 'Randevunuz $formattedDate saat $time için onay bekliyor.',
        appointmentId: appointmentId,
      );

      // STEP 15: Berbere bildirim gönder
      await _notificationService.createNotification(
        userId: barberId,
        role: 'barber',
        type: 'created',
        message: 'Yeni randevu talebi: $formattedDate saat $time',
        appointmentId: appointmentId,
      );
      
      // Başarılı - void method, return value yok
    } catch (e) {
      // Enhanced error logging
      debugPrint('[APPOINTMENT_ERROR] creation failed | customer: $customerId | barber: $barberId | error: ${e.toString()}');
      rethrow; // Exception'ı yukarı fırlat, caller'a hata bildirimi için
    }
  }

  /// Randevu çakışması kontrolü
  /// 
  /// Aynı berber + tarih + saat için mevcut randevu var mı kontrol eder
  /// Cancelled randevular ignore edilir
  /// 
  /// Returns: true if conflict exists, false otherwise
  Future<bool> _checkConflict({
    required String barberId,
    required DateTime date,
    required String time,
  }) async {
    try {
      // Normalize date to start of day for consistent comparison
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final conflictQuery = await _appointmentsCollection
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Filter by time and active status
      for (var doc in conflictQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final docTime = data['time'] as String?;
        final docStatus = data['status'] as String?;

        // Check if same time and not cancelled
        if (docTime == time && docStatus != 'cancelled') {
          debugPrint('Conflict detected: barberId=$barberId, date=$date, time=$time');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Çakışma kontrolü hatası: $e');
      // On error, allow booking (fail-open for better UX)
      return false;
    }
  }

  /// Belirli bir berberin tüm randevularını getirir
  /// 
  /// [barberId] Randevuları çekilecek berberin uid'si
  /// Returns: Randevu listesi (Stream)
  /// Sadece aktif randevular (pending, approved) - completed/cancelled hariç
  Stream<QuerySnapshot> getBarberAppointments(String barberId) {
    try {
      return _appointmentsCollection
          .where('barberId', isEqualTo: barberId)
          .where('status', whereIn: ['pending', 'approved']) // Sadece aktif randevular
          .orderBy('date', descending: false) // Yakın randevular üstte
          .snapshots();
    } catch (e) {
      debugPrint('Randevular çekilirken hata: $e');
      rethrow;
    }
  }

  /// Belirli bir müşterinin tüm randevularını getirir
  /// 
  /// [customerId] Randevuları çekilecek müşterinin uid'si
  /// Returns: Randevu listesi (Stream)
  /// Sadece aktif randevular (pending, approved) - completed/cancelled hariç
  Stream<QuerySnapshot> getCustomerAppointments(String customerId) {
    try {
      return _appointmentsCollection
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['pending', 'approved']) // Sadece aktif randevular
          .orderBy('date', descending: false) // Yakın randevular üstte
          .snapshots();
    } catch (e) {
      debugPrint('Randevular çekilirken hata: $e');
      rethrow;
    }
  }

  /// Berberin geçmiş randevularını getirir
  /// 
  /// [barberId] Geçmiş randevuları çekilecek berberin uid'si
  /// Returns: Tamamlanmış ve iptal edilmiş randevular (Stream)
  Stream<QuerySnapshot> getBarberHistoryAppointments(String barberId) {
    try {
      return _appointmentsCollection
          .where('barberId', isEqualTo: barberId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Geçmiş randevular çekilirken hata: $e');
      rethrow;
    }
  }

  /// Müşterinin geçmiş randevularını getirir
  /// 
  /// [customerId] Geçmiş randevuları çekilecek müşterinin uid'si
  /// Returns: Tamamlanmış ve iptal edilmiş randevular (Stream)
  Stream<QuerySnapshot> getCustomerHistoryAppointments(String customerId) {
    try {
      return _appointmentsCollection
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Müşteri geçmiş randevular çekilirken hata: $e');
      rethrow;
    }
  }

  /// Randevu durumunu günceller
  /// 
  /// [appointmentId] Güncellenecek randevunun ID'si
  /// [newStatus] Yeni durum (pending, approved, cancelled, completed)
  /// [requestedBy] İsteği yapan ('customer' veya 'barber')
  /// 
  /// İzin verilen geçişler:
  /// - pending → approved | cancelled
  /// - approved → completed
  /// - cancelled → değiştirilemez
  /// - completed → değiştirilemez
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String newStatus,
    String requestedBy = 'barber', // STEP 14: Track who is making the change
  }) async {
    try {
      // Geçerli status kontrolü
      if (!['pending', 'approved', 'cancelled', 'completed'].contains(newStatus)) {
        throw Exception('Geçersiz durum: $newStatus');
      }

      // Mevcut randevuyu al
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      
      if (!doc.exists) {
        throw Exception('Randevu bulunamadı');
      }

      final data = doc.data() as Map<String, dynamic>?;
      final currentStatus = data?['status'] as String? ?? 'pending';

      // STEP 14: Cancellation time window check
      if (newStatus == 'cancelled' && requestedBy == 'customer') {
        final date = (data?['date'] as Timestamp?)?.toDate();
        final time = data?['time'] as String?;
        
        if (date != null && time != null) {
          final appointmentDateTime = _combineDateTime(date, time);
          final now = DateTime.now();
          final hoursUntilAppointment = appointmentDateTime.difference(now).inMinutes;
          
          // Müşteri randevuya 60 dakikadan az kala iptal edemez
          if (hoursUntilAppointment < 60) {
            throw Exception('Randevu saatine çok az kaldığı için iptal edilemez.');
          }
        }
      }

      // Geçiş validasyonu
      final isValidTransition = _isValidStatusTransition(currentStatus, newStatus);
      
      if (!isValidTransition) {
        throw Exception('$currentStatus durumundan $newStatus durumuna geçiş yapılamaz');
      }

      // Firestore'u güncelle
      await _appointmentsCollection.doc(appointmentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Log successful status change with full context
      debugPrint('[APPOINTMENT] status: $currentStatus → $newStatus | id: $appointmentId | by: $requestedBy');

      // STEP 15: Status değişiminde notification gönder
      final customerId = data?['customerId'] as String?;
      final barberId = data?['barberId'] as String?;

      if (customerId != null && barberId != null) {
        // Status'a göre bildirim mesajları
        if (newStatus == 'approved') {
          // Randevu tarih ve saatini al
          final date = (data?['date'] as Timestamp?)?.toDate();
          final time = data?['time'] as String?;
          
          String message = 'Randevunuz onaylandı.';
          
          if (date != null && time != null) {
            final formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
            final appointmentDateTime = _combineDateTime(date, time);
            final now = DateTime.now();
            final remaining = appointmentDateTime.difference(now);
            final countdownText = _formatCountdownForNotification(remaining);
            
            // Müşteriye onay bildirimi (tarih/saat ve countdown bilgisiyle)
            message = countdownText.isNotEmpty
                ? 'Randevunuz onaylandı! $formattedDate saat $time - Randevunuza $countdownText kaldı.'
                : 'Randevunuz onaylandı! $formattedDate saat $time';
          }
          
          await _notificationService.createNotification(
            userId: customerId,
            role: 'customer',
            type: 'approved',
            message: message,
            appointmentId: appointmentId,
          );
        } else if (newStatus == 'cancelled') {
          // Randevu tarih ve saatini al
          final date = (data?['date'] as Timestamp?)?.toDate();
          final time = data?['time'] as String?;
          String dateTimeInfo = '';
          
          if (date != null && time != null) {
            final formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
            dateTimeInfo = ' ($formattedDate saat $time)';
          }
          
          // Kimin iptal ettiğine göre bildir
          if (requestedBy == 'barber') {
            // Müşteriye iptal bildirimi
            await _notificationService.createNotification(
              userId: customerId,
              role: 'customer',
              type: 'cancelled',
              message: 'Randevunuz berber tarafından iptal edildi.$dateTimeInfo',
              appointmentId: appointmentId,
            );
          } else {
            // Berbere iptal bildirimi
            await _notificationService.createNotification(
              userId: barberId,
              role: 'barber',
              type: 'cancelled',
              message: 'Bir randevu müşteri tarafından iptal edildi.$dateTimeInfo',
              appointmentId: appointmentId,
            );
          }
        } else if (newStatus == 'completed') {
          // Randevu tarih ve saatini al
          final date = (data?['date'] as Timestamp?)?.toDate();
          final time = data?['time'] as String?;
          String message = 'Randevunuz tamamlandı. Teşekkür ederiz.';
          
          if (date != null && time != null) {
            final formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
            message = 'Randevunuz tamamlandı! ($formattedDate saat $time) Teşekkür ederiz.';
          }
          
          // Müşteriye tamamlanma bildirimi
          await _notificationService.createNotification(
            userId: customerId,
            role: 'customer',
            type: 'completed',
            message: message,
            appointmentId: appointmentId,
          );
        }
      }
      
    } catch (e) {
      // Enhanced error logging with context
      debugPrint('[APPOINTMENT_ERROR] status update failed | id: $appointmentId | target: $newStatus | by: $requestedBy | error: ${e.toString()}');
      rethrow;
    }
  }

  /// Status geçiş validasyonu
  bool _isValidStatusTransition(String from, String to) {
    switch (from) {
      case 'pending':
        return to == 'approved' || to == 'cancelled';
      case 'approved':
        return to == 'completed';
      case 'cancelled':
      case 'completed':
        return false; // Son durumlar, değiştirilemez
      default:
        return false;
    }
  }

  /// Tarih ve saat string'ini birleştir
  /// STEP 14: Helper for time validation
  DateTime _combineDateTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Kalan süreyi bildirim için formatla
  /// Duration'ı Türkçe okunabilir metne çevirir
  String _formatCountdownForNotification(Duration duration) {
    if (duration.isNegative) {
      return '';
    }

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    final parts = <String>[];

    if (days > 0) {
      parts.add('$days gün');
    }
    if (hours > 0) {
      parts.add('$hours saat');
    }
    if (minutes > 0) {
      parts.add('$minutes dakika');
    }

    return parts.isEmpty ? '' : parts.join(' ');
  }

  /// Ay numarasını Türkçe ay adına çevir
  String _getMonthName(int month) {
    const monthNames = [
      '', // 0 index boş (ay 1'den başlıyor)
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }

  /// Randevuyu sil (geçmiş randevular için)
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _appointmentsCollection.doc(appointmentId).delete();
      debugPrint('Appointment deleted: $appointmentId');
    } catch (e) {
      debugPrint('Randevu silme hatası: $e');
      rethrow;
    }
  }
}
