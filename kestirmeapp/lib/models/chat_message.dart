/// Chat mesaj modeli
/// Kullanıcı ve AI asistanı arasındaki mesajları temsil eder
class ChatMessage {
  final String id;
  final String content;
  final String role; // 'user' veya 'assistant'
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  /// JSON'dan ChatMessage oluştur
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// ChatMessage'ı JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Yeni bir kullanıcı mesajı oluştur
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: 'user',
      timestamp: DateTime.now(),
    );
  }

  /// Yeni bir asistan mesajı oluştur
  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: 'assistant',
      timestamp: DateTime.now(),
    );
  }

  /// Mesajın kullanıcıdan mı geldiğini kontrol et
  bool get isUser => role == 'user';

  /// Mesajın asistandan mı geldiğini kontrol et
  bool get isAssistant => role == 'assistant';
}
