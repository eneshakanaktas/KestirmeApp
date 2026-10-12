import 'package:flutter/foundation.dart';

/// Berber email'ine göre salon adı döndüren helper sınıf
class SalonNameHelper {
  /// Email'e göre salon adı mapping
  static const Map<String, String> _salonNames = {
    'enes123@gmail.com': 'ENES KUAFÖR',
    'rago@gmail.com': 'BERBER RAGO',
    'hamza@gmail.com': 'Hamza Image Maker',
  };

  /// Email'den salon adını al
  /// 
  /// Eğer email kayıtlı değilse firestore'daki salonName kullanılır
  /// veya "Berber Salonu" default değeri döner
  static String getSalonName({
    required String? email,
    String? firestoreSalonName,
  }) {
    // 1. Önce sabit mapping'e bak
    if (email != null && _salonNames.containsKey(email.toLowerCase())) {
      return _salonNames[email.toLowerCase()]!;
    }
    
    // 2. Firestore'dan gelen salonName varsa onu kullan
    if (firestoreSalonName != null && firestoreSalonName.isNotEmpty) {
      return firestoreSalonName;
    }
    
    // 3. Default
    return 'Berber Salonu';
  }

  /// Aktif salonların listesini döndür (AI chatbot için)
  static List<String> getActiveSalonNames() {
    return _salonNames.values.toList();
  }

  /// Email'den berber adını çıkar (@ işaretinden önceki kısım)
  static String getBarberNameFromEmail(String email) {
    final username = email.split('@').first;
    return username.replaceAll(RegExp(r'[0-9]'), '').trim();
  }

  /// Salon adından email'i al (AI chatbot için)
  /// ENES KUAFÖR → enes123@gmail.com
  static String? getEmailFromSalonName(String? salonName) {
    if (salonName == null || salonName.isEmpty) return null;
    
    final query = salonName.toLowerCase().trim();
    
    // Salon adına göre email mapping
    for (var entry in _salonNames.entries) {
      final salon = entry.value.toLowerCase();
      
      // Tam eşleşme veya contains kontrolü
      if (salon == query || 
          salon.contains(query) || 
          query.contains(salon.split(' ').first.toLowerCase())) {
        return entry.key;
      }
    }
    
    // Sayı ile seçim (1, 2, 3)
    if (query == '1' || query.contains('enes')) {
      return 'enes123@gmail.com';
    } else if (query == '2' || query.contains('rago')) {
      return 'rago@gmail.com';
    } else if (query == '3' || query.contains('hamza')) {
      return 'hamza@gmail.com';
    }
    
    return null;
  }

  /// Debug için tüm mapping'i göster
  static void printMapping() {
    if (kDebugMode) {
      print('=== Salon Name Mapping ===');
      _salonNames.forEach((email, salon) {
        print('$email → $salon');
      });
    }
  }
}
