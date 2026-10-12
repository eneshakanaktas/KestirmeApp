import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// Chat geçmişini local storage'da yöneten servis
class ChatStorageService {
  /// Kullanıcıya özel chat history key'i oluştur
  String _getChatHistoryKey(String uid) => 'chat_history_$uid';

  /// Chat geçmişini kaydet (kullanıcıya özel)
  Future<void> saveChatHistory(List<ChatMessage> messages, String uid) async {
    try {
      // UID kontrolü - giriş yapılmamışsa kaydetme
      if (uid.isEmpty) {
        print('Chat geçmişi kaydedilemedi: UID boş');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_getChatHistoryKey(uid), jsonString);
    } catch (e) {
      print('Chat geçmişi kaydedilirken hata: $e');
    }
  }

  /// Chat geçmişini yükle (kullanıcıya özel)
  Future<List<ChatMessage>> loadChatHistory(String uid) async {
    try {
      // UID kontrolü - giriş yapılmamışsa boş liste döndür
      if (uid.isEmpty) {
        print('Chat geçmişi yüklenemedi: UID boş');
        return [];
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getChatHistoryKey(uid));
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Chat geçmişi yüklenirken hata: $e');
      return [];
    }
  }

  /// Chat geçmişini temizle (kullanıcıya özel)
  Future<void> clearChatHistory(String uid) async {
    try {
      // UID kontrolü
      if (uid.isEmpty) {
        print('Chat geçmişi temizlenemedi: UID boş');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getChatHistoryKey(uid));
    } catch (e) {
      print('Chat geçmişi temizlenirken hata: $e');
    }
  }
}
