import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Berber işlemlerini yöneten servis
/// Firestore'da barbers collection'ı üzerinde okuma ve yazma operasyonları yapar
class BarberService {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Barbers collection referansı
  CollectionReference get _barbersCollection => _firestore.collection('barbers');

  /// Aktif berberleri getirir
  /// 
  /// Returns: Aktif berber listesi (Stream)
  Stream<QuerySnapshot> getActiveBarbers() {
    try {
      return _barbersCollection
          .where('isActive', isEqualTo: true)
          .snapshots();
    } catch (e) {
      debugPrint('Aktif berberler çekilirken hata: $e');
      rethrow;
    }
  }

  /// Belirli bir berberin bilgilerini getirir
  /// 
  /// [barberId] Berber uid'si
  /// Returns: Berber bilgileri
  Future<Map<String, dynamic>?> getBarberById(String barberId) async {
    try {
      final doc = await _barbersCollection.doc(barberId).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Berber bilgisi getirilemedi: $e');
      return null;
    }
  }

  /// Berber profili var mı kontrol eder, yoksa oluşturur
  /// 
  /// [barberId] Berber uid'si
  /// [email] Berber email (opsiyonel)
  /// Returns: Berber profil bilgileri
  Future<Map<String, dynamic>> getOrCreateBarberProfile({
    required String barberId,
    String? email,
  }) async {
    try {
      final doc = await _barbersCollection.doc(barberId).get();
      
      if (doc.exists) {
        // Profil varsa döndür
        return doc.data() as Map<String, dynamic>;
      }
      
      // Profil yoksa oluştur
      final profileData = {
        'uid': barberId,
        'email': email,
        'salonName': null,
        'phone': null,
        'address': null,
        'isActive': false, // Varsayılan olarak pasif
        'ratingCount': 0,  // Değerlendirme sayısı - başlangıç değeri
        'ratingTotal': 0,  // Toplam puan - başlangıç değeri
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await _barbersCollection.doc(barberId).set(profileData);
      
      debugPrint('Berber profili oluşturuldu: $barberId');
      
      return profileData;
    } catch (e) {
      debugPrint('Berber profili oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Berberin aktiflik durumunu günceller
  /// 
  /// [barberId] Berber uid'si
  /// [isActive] Yeni aktiflik durumu
  Future<void> updateBarberActiveStatus({
    required String barberId,
    required bool isActive,
  }) async {
    try {
      await _barbersCollection.doc(barberId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Berber aktiflik durumu güncellendi: $barberId -> $isActive');
    } catch (e) {
      debugPrint('Aktiflik durumu güncellenemedi: $e');
      rethrow;
    }
  }

  /// Berberin profil bilgilerini gerçek zamanlı dinler
  /// 
  /// [barberId] Berber uid'si
  /// Returns: Berber profil stream
  Stream<DocumentSnapshot> getBarberProfileStream(String barberId) {
    try {
      return _barbersCollection.doc(barberId).snapshots();
    } catch (e) {
      debugPrint('Berber profil stream hatası: $e');
      rethrow;
    }
  }
}
