import 'dart:convert';

/// AI cevaplarını parse ederek randevu oluşturma intentlerini tespit eden servis
class AiAppointmentParser {
  /// AI cevabında JSON randevu intent'i var mı kontrol et
  static bool hasAppointmentIntent(String message) {
    try {
      // JSON pattern ara
      final jsonPattern = RegExp(r'\{[^}]*"action"\s*:\s*"create_appointment"[^}]*\}');
      return jsonPattern.hasMatch(message);
    } catch (e) {
      return false;
    }
  }

  /// AI cevabından randevu intentini parse et
  static AiAppointmentIntent? parseAppointmentIntent(String message) {
    try {
      // JSON bloğunu bul
      final jsonPattern = RegExp(r'\{[^}]*"action"\s*:\s*"create_appointment"[^}]*\}');
      final match = jsonPattern.firstMatch(message);
      
      if (match == null) return null;
      
      final jsonString = match.group(0);
      if (jsonString == null) return null;
      
      // JSON parse et
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Gerekli alanları kontrol et
      if (json['action'] != 'create_appointment') return null;
      
      return AiAppointmentIntent(
        date: json['date'] as String?,
        time: json['time'] as String?,
        barberId: json['barberId'] as String?,
        barberName: json['barberName'] as String?,
        customerName: json['customerName'] as String?,
        customerPhone: json['customerPhone'] as String?,
        message: json['message'] as String? ?? 'Randevunuz oluşturuluyor...',
      );
    } catch (e) {
      print('Randevu intent parse hatası: $e');
      return null;
    }
  }

  /// Türkçe tarih ifadelerini DateTime'a çevir
  static DateTime? parseRelativeDate(String dateText) {
    final now = DateTime.now();
    final lowerText = dateText.toLowerCase().trim();

    // Bugün
    if (lowerText.contains('bugün')) {
      return DateTime(now.year, now.month, now.day);
    }

    // Yarın
    if (lowerText.contains('yarın')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }

    // Gelecek hafta
    if (lowerText.contains('gelecek hafta')) {
      final nextWeek = now.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day);
    }

    // ISO format (YYYY-MM-DD)
    try {
      return DateTime.parse(dateText);
    } catch (e) {
      return null;
    }
  }
}

/// AI'dan gelen randevu oluşturma intent modeli
class AiAppointmentIntent {
  final String? date;
  final String? time;
  final String? barberId;
  final String? barberName;
  final String? customerName;    // YENİ
  final String? customerPhone;   // YENİ
  final String message;

  AiAppointmentIntent({
    this.date,
    this.time,
    this.barberId,
    this.barberName,
    this.customerName,
    this.customerPhone,
    required this.message,
  });

  /// Tüm gerekli bilgiler var mı?
  bool get isComplete =>
      date != null &&
      time != null &&
      customerName != null &&
      customerPhone != null &&
      customerPhone!.startsWith('+90');

  /// JSON'a çevir
  Map<String, dynamic> toJson() => {
    'date': date,
    'time': time,
    'barberId': barberId,
    'barberName': barberName,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'message': message,
  };
}
