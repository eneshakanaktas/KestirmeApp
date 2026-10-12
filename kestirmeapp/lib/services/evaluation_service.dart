import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Değerlendirme işlemlerini yöneten servis
/// 
/// Atomik transaction ile değerlendirme yazma ve berber rating güncelleme
/// Çift yazma koruması: her randevu SADECE BİR KEZ değerlendirilebilir
class EvaluationService {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection referansları
  CollectionReference get _evaluationsCollection => _firestore.collection('evaluations');
  CollectionReference get _appointmentsCollection => _firestore.collection('appointments');
  CollectionReference get _barbersCollection => _firestore.collection('barbers');

  /// Değerlendirme gönderir (ONE-TIME, ATOMIC)
  /// 
  /// Transaction içinde:
  /// 1. Randevunun completed olduğunu ve daha önce değerlendirilmediğini kontrol et
  /// 2. Evaluation dokümantı oluştur
  /// 3. Randevuyu isEvaluated = true olarak işaretle (idempotency lock)
  /// 4. Berber rating agregalarını güncelle
  /// 
  /// [appointmentId] Değerlendirilecek randevunun ID'si
  /// [barberId] Berberin UID'si
  /// [customerId] Müşterinin UID'si
  /// [rating] Puan (1-5 arası)
  /// [comment] Yorum (opsiyonel)
  /// 
  /// Throws: Exception if:
  /// - Randevu bulunamazsa
  /// - Randevu completed değilse
  /// - Randevu zaten değerlendirildiyse
  /// - Rating geçerli aralıkta değilse (1-5)
  Future<void> submitEvaluation({
    required String appointmentId,
    required String barberId,
    required String customerId,
    required int rating,
    String? comment,
  }) async {
    // İstemci tarafı validasyon
    if (rating < 1 || rating > 5) {
      throw Exception('Puan 1 ile 5 arasında olmalıdır');
    }

    try {
      // ATOMIK TRANSACTION - tam deterministik, all-or-nothing
      await _firestore.runTransaction((transaction) async {
        // 1. Randevu dokümantını oku
        final appointmentRef = _appointmentsCollection.doc(appointmentId);
        final appointmentSnap = await transaction.get(appointmentRef);
        
        if (!appointmentSnap.exists) {
          throw Exception('Randevu bulunamadı');
        }
        
        final appointmentData = appointmentSnap.data() as Map<String, dynamic>;
        final status = appointmentData['status'] as String?;
        final isEvaluated = appointmentData['isEvaluated'] as bool? ?? false;
        
        // 2. Guard: sadece completed ve henüz değerlendirilmemiş randevular
        if (status != 'completed') {
          throw Exception('Sadece tamamlanmış randevular değerlendirilebilir');
        }
        
        if (isEvaluated) {
          // Log duplicate evaluation attempt
          debugPrint('[EVALUATION_DUPLICATE] attempt blocked | appointmentId: $appointmentId | customerId: $customerId');
          throw Exception('Bu randevu zaten değerlendirilmiş');
        }
        
        // 3. Evaluation dokümantı oluştur - barbers/{barberId}/reviews subcollection
        final reviewRef = _barbersCollection
            .doc(barberId)
            .collection('reviews')
            .doc();
        transaction.set(reviewRef, {
          'appointmentId': appointmentId,
          'userId': customerId,
          'rating': rating,
          'comment': comment ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // 4. Randevuyu değerlendirildi olarak işaretle (IDEMPOTENCY LOCK)
        transaction.update(appointmentRef, {
          'isEvaluated': true,
          'evaluatedAt': FieldValue.serverTimestamp(),
        });
        
        // 5. Berber rating agregalarını güncelle
        final barberRef = _barbersCollection.doc(barberId);
        final barberSnap = await transaction.get(barberRef);
        
        if (barberSnap.exists) {
          final barberData = barberSnap.data() as Map<String, dynamic>;
          final currentCount = (barberData['ratingCount'] as num?)?.toInt() ?? 0;
          final currentTotal = (barberData['ratingTotal'] as num?)?.toInt() ?? 0;
          
          // Agregaları atomik olarak güncelle
          transaction.update(barberRef, {
            'ratingCount': currentCount + 1,
            'ratingTotal': currentTotal + rating,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Berber dokümantı yoksa - ilk rating ile oluştur
          transaction.set(barberRef, {
            'ratingCount': 1,
            'ratingTotal': rating,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
      
      // Structured success logging
      debugPrint('[EVALUATION] submitted | customer: $customerId | barber: $barberId | rating: $rating | appointmentId: $appointmentId');
    } catch (e) {
      // Enhanced error logging with categorization
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('zaten değerlendirilmiş')) {
        // Already logged in duplicate check
      } else if (errorMsg.contains('permission')) {
        debugPrint('[EVALUATION_ERROR] permission denied | appointmentId: $appointmentId | customerId: $customerId');
      } else {
        debugPrint('[EVALUATION_ERROR] submission failed | appointmentId: $appointmentId | error: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Berberin ortalama puanını hesaplar
  /// 
  /// İstemci tarafında ortalama hesaplamaz, sadece kayıtlı verileri döndürür
  /// 
  /// [barberId] Berberin UID'si
  /// Returns: Map with 'averageRating' (double) and 'ratingCount' (int), or null
  Future<Map<String, dynamic>?> getBarberRating(String barberId) async {
    try {
      final doc = await _barbersCollection.doc(barberId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
      final total = (data['ratingTotal'] as num?)?.toInt() ?? 0;
      
      if (count == 0) {
        return {'averageRating': 0.0, 'ratingCount': 0};
      }
      
      final average = total / count;
      
      return {
        'averageRating': double.parse(average.toStringAsFixed(1)),
        'ratingCount': count,
      };
    } catch (e) {
      debugPrint('Berber puanı alınırken hata: $e');
      return null;
    }
  }
}
