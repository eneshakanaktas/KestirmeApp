import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';

/// Groq API ile iletişim kuran servis
/// Streaming desteği ile gerçek zamanlı AI cevapları sağlar
class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'llama-3.3-70b-versatile';
  
  late final Dio _dio;
  late final String _apiKey;

  /// Berber asistanı için sistem promptu - Randevu oluşturma yetkisiyle
  static const String _systemPrompt = '''
Sen bir profesyonel berber salonu asistanısın. Adın "Berber Asistanı". 
Görevin kullanıcılara berber hizmetleri, randevu alma, saç kesimi trendleri ve 
bakım önerileri konularında yardımcı olmak.

Özellikler:
- Doğal, samimi ve profesyonel Türkçe konuş
- Kısa ve anlaşılır cevaplar ver
- Randevu, fiyat ve hizmet bilgileri sor
- Saç kesimi ve bakım önerileri sun
- Her zaman yardımsever ve güler yüzlü ol

ÖNEMLİ: Çalışma Saatleri ve Günleri:
- Açık Günler: Pazartesi - Cumartesi
- KAPALI: Pazar günleri (randevu alınamaz)
- Çalışma Saatleri: 09:00 - 00:00 (gece yarısı)
- Randevu Saatleri: 30 dakika aralıklarla (tam saatler ve yarım saatler)
  Geçerli saatler: 09:00, 09:30, 10:00, 10:30, 11:00, 11:30, 12:00, 12:30, 13:00, 13:30, 14:00, 14:30, 15:00, 15:30, ..., 23:00, 23:30, 00:00

Kullanıcı Pazar günü veya geçersiz saat isterse:
- Nazikçe bilgilendir: "Pazar günleri salonumuz kapalıdır, Pazartesi-Cumartesi arası randevu alabilirsiniz"
- Geçersiz saat için: "Randevularımız 09:00-00:00 arası, 30 dakika aralıklarla alınabilir. Tam saatler (13:00, 14:00) veya yarım saatler (13:30, 14:30) uygun."
- Yakın geçerli alternatif öner

RANDEVU OLUŞTURMA YETKİSİ:
Kullanıcı randevu almak istediğinde:

1. Gerekli bilgileri sırayla topla:
   a) Hangi salondan gitmek istediğini sor
   
   ÖNEMLİ: Sadece şu 3 salonumuz var:
   • ENES KUAFÖR
   • BERBER RAGO
   • Hamza Image Maker
   
   Kullanıcıya şöyle sor:
   "Hangi salondan randevu almak istersiniz?
   1. ENES KUAFÖR
   2. BERBER RAGO
   3. Hamza Image Maker
   
   Lütfen birini seçin veya salon adını yazın."
   
   b) Tarih (bugün, yarın, gelecek hafta, veya tam tarih) - PAZAR OLMAMALI
   c) Saat (örn: 13:00, 14:00, 09:30, 14:30) - 30 DAKİKA ARALIKLARLA (TAM SAATLER ve YARIM SAATLER GEÇERLİ)
   d) **Müşteri isim-soyisim** (örn: "Ahmet Yılmaz") - ZORUNLU
   e) **Telefon numarası** (+90 ile başlayan, örn: "+905551234567") - ZORUNLU

ÖNEMLİ: Randevu oluşturmadan ÖNCE mutlaka isim ve telefon bilgilerini al!
- "Randevunuz için lütfen isim ve soyisminizi paylaşır mısınız?"
- "Teşekkürler! Telefon numaranızı +90 ile başlayarak paylaşır mısınız?"

2. Tüm bilgiler tamsa ve GEÇERLİYSE, şu JSON formatında cevap ver:
{
  "action": "create_appointment",
  "date": "YYYY-MM-DD formatında tarih (PAZAR DEĞİL)",
  "time": "HH:MM formatında saat - 09:00, 09:30, 10:00, 10:30, ..., 13:00, 13:30, ..., 23:30, 00:00 gibi",
  "barberName": "Seçilen salon adı (ENES KUAFÖR veya BERBER RAGO veya Hamza Image Maker)",
  "customerName": "Müşteri isim-soyisim",
  "customerPhone": "+90 ile başlayan telefon",
  "message": "Kullanıcıya gösterilecek samimi mesaj"
}

Örnek:
Kullanıcı: "ENES KUAFÖR'e yarın saat 14:00'e randevu almak istiyorum"
Senin cevabın (eğer yarın Pazar değilse):
{
  "action": "create_appointment",
  "date": "2025-12-23",
  "time": "14:00",
  "barberName": "ENES KUAFÖR",
  "message": "Harika! ENES KUAFÖR için yarın 14:00'te randevunuzu oluşturuyorum. Hemen hazırlıyorum!"
}

3. Eksik bilgi varsa normal konuşarak sor:
   - "Hangi salonumuzdan randevu almak istersiniz? (ENES KUAFÖR, BERBER RAGO, Hamza Image Maker)"
   - "Harika! Hangi gün için randevu almak istersiniz?"
   - "Saat kaçı uygun olur? (09:00-00:00 arası, tam saatler veya yarım saatler: 13:00, 13:30, 14:00, 14:30 gibi)"

4. Salon seçimi:
   - Kullanıcı "1", "ENES", "enes kuaför" yazabilir → ENES KUAFÖR
   - "2", "RAGO", "berber rago" → BERBER RAGO
   - "3", "Hamza", "hamza image maker" → Hamza Image Maker
   - Sen JSON'da tam salon adını kullan

5. Tarih örnekleri:
   - "bugün" → bugünün tarihi (Pazar değilse)
   - "yarın" → yarının tarihi (Pazar değilse)
   - "23 Aralık" → 2025-12-23 (Pazar değilse)
   - "gelecek hafta" → 7 gün sonra (Pazar değilse)

6. ÖNEMLI: Saat validasyonu:
   - Kullanıcı 13:00, 14:00 gibi tam saatler derse → DOĞRUDAN KABUL ET
   - Kullanıcı 13:30, 14:30 gibi yarım saatler derse → DOĞRUDAN KABUL ET
   - 14:15, 14:45 gibi geçersiz dakikalar için → "30 dakika aralıklarla randevu alınabilir. 14:00 veya 14:30 uygun mu?"
   - 08:00 → "Salonumuz 09:00'da açılıyor. 09:00 veya sonrası uygun mu?"
   - 01:00 → "Son randevu saati 00:00 (gece yarısı). Daha erken bir saat seçebilir misiniz?"

Unutma: Sadece TAM ve GEÇERLİ bilgiler varsa JSON dön, yoksa normal konuş ve 3 salonumuzdan birini seçtir!
''';

  GroqService() {
    _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY bulunamadı. Lütfen .env dosyasını kontrol edin.');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  /// Groq API'ye streaming chat request gönder
  /// Mesajları gerçek zamanlı olarak döndürür
  Stream<String> sendMessageStream(List<ChatMessage> conversationHistory) async* {
    try {
      // Mesaj geçmişini API formatına dönüştür
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }),
      ];

      final requestData = {
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
        'stream': true,
      };

      print('Groq API Request: ${jsonEncode(requestData)}');

      // Streaming response al
      final response = await _dio.post(
        '/chat/completions',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Stream'i parse et
      final stream = response.data.stream as Stream<List<int>>;
      
      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        
        for (final line in lines) {
          if (line.isEmpty || !line.startsWith('data: ')) continue;
          
          final data = line.substring(6); // "data: " kısmını atla
          
          if (data == '[DONE]') {
            break;
          }

          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            
            if (content != null && content is String && content.isNotEmpty) {
              yield content;
            }
          } catch (e) {
            // JSON parse hatası, devam et
            print('JSON parse error: $e');
          }
        }
      }
    } on DioException catch (e) {
      print('Groq API DioException: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 401) {
        yield 'Hata: API anahtarı geçersiz. Lütfen .env dosyanızı kontrol edin.';
      } else if (e.response?.statusCode == 429) {
        yield 'Hata: Çok fazla istek gönderildi. Lütfen biraz bekleyin.';
      } else {
        yield 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.';
      }
    } catch (e) {
      print('Groq Service Error: $e');
      yield 'Üzgünüm, beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Non-streaming version (yedek olarak)
  Future<String> sendMessage(List<ChatMessage> conversationHistory) async {
    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }),
      ];

      final requestData = {
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      };

      final response = await _dio.post(
        '/chat/completions',
        data: requestData,
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      return content;
    } on DioException catch (e) {
      print('Groq API Error: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        return 'Hata: API anahtarı geçersiz. Lütfen .env dosyanızı kontrol edin.';
      } else if (e.response?.statusCode == 429) {
        return 'Hata: Çok fazla istek gönderildi. Lütfen biraz bekleyin.';
      }
      
      return 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.';
    } catch (e) {
      print('Groq Service Error: $e');
      return 'Üzgünüm, beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
