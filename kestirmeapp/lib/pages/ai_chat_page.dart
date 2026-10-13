import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/salon_name_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/groq_service.dart';
import '../services/ai_appointment_parser.dart';
import '../services/appointment_service.dart';
import '../models/chat_message.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium AI Chat Sayfası
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final GroqService _groqService = GroqService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage.assistant(
      '''✨ Merhaba! Ben KESTİRME AI Asistan'ım.

Size yardımcı olabileceğim konular:
• 📅 Randevu oluşturma
• 💇 Saç modeli önerileri  
• 📋 Hizmet ve fiyat bilgisi
• ⏰ Uygun saat sorgulaması

Nasıl yardımcı olabilirim?''',
    ));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage.user(text));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _groqService.sendMessage(_messages);
      
      // JSON içeriğini kullanıcıdan gizle, sadece anlamlı mesajı göster
      String displayMessage = _extractUserFriendlyMessage(response);
      
      setState(() {
        _messages.add(ChatMessage.assistant(displayMessage));
        _isLoading = false;
      });

      // Check for appointment intent
      final intent = AiAppointmentParser.parseAppointmentIntent(response);
      if (intent != null && intent.isComplete) {
        _showAppointmentConfirmDialog(intent);
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage.assistant(
          'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.',
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }


  /// AI response'tan kullanıcı dostu mesajı çıkar (JSON'u tamamen gizle)
  String _extractUserFriendlyMessage(String response) {
    String cleaned = response;
    
    // 1. Tüm JSON bloklarını temizle (metin + JSON durumu için)
    // Regex ile { } arasındaki tüm JSON'ları bul ve temizle
    final jsonPattern = RegExp(r'\{[^{}]*\}', multiLine: true);
    
    // JSON içinde "message" alanını çıkar
    final matches = jsonPattern.allMatches(response);
    String extractedMessage = '';
    
    for (final match in matches) {
      try {
        final jsonString = match.group(0);
        if (jsonString != null) {
          final jsonData = jsonDecode(jsonString);
          
          // "message" alanı varsa al
          if (jsonData is Map && jsonData.containsKey('message')) {
            final msg = jsonData['message'];
            if (msg != null && msg.toString().isNotEmpty) {
              extractedMessage += msg.toString() + '\n';
            }
          }
        }
      } catch (e) {
        // JSON parse hatası, devam et
      }
    }
    
    // 2. Tüm JSON bloklarını response'tan sil
    cleaned = cleaned.replaceAll(jsonPattern, '');
    
    // 3. Eğer JSON'dan message çıkarıldıysa onu kullan
    if (extractedMessage.isNotEmpty) {
      cleaned = extractedMessage.trim() + '\n' + cleaned;
    }
    
    // 4. "action", "date", "time" gibi teknik alanları içeren satırları temizle
    final technicalPatterns = [
      RegExp(r'"action"\s*:\s*"[^"]*"', multiLine: true),
      RegExp(r'"date"\s*:\s*"[^"]*"', multiLine: true),
      RegExp(r'"time"\s*:\s*"[^"]*"', multiLine: true),
      RegExp(r'"barberName"\s*:\s*"[^"]*"', multiLine: true),
      RegExp(r'"barberId"\s*:\s*"[^"]*"', multiLine: true),
      RegExp(r'"customerName"\s*:\s*"[^"]*"', multiLine: true),
      RegExp(r'"customerPhone"\s*:\s*"[^"]*"', multiLine: true),
    ];
    
    for (final pattern in technicalPatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }
    
    // 5. Boş satırları ve fazla boşlukları temizle
    cleaned = cleaned
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n')
        .trim();
    
    // 6. Eğer hiçbir şey kalmadıysa varsayılan mesaj
    if (cleaned.isEmpty || cleaned.length < 5) {
      return 'Randevu bilgilerinizi işliyorum...';
    }
    
    return cleaned;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAppointmentConfirmDialog(AiAppointmentIntent intent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: const Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Randevu Onayla', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfo('Tarih', intent.date ?? '-'),
            _buildDialogInfo('Saat', intent.time ?? '-'),
            _buildDialogInfo('Müşteri', intent.customerName ?? '-'),
            _buildDialogInfo('Telefon', intent.customerPhone ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _createAppointment(intent);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Randevu Oluştur', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _createAppointment(AiAppointmentIntent intent) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || intent.date == null || intent.time == null) return;

    try {
      // AI'dan gelen barberName ile eşleşen berberi bul
      String? barberId;
      
      if (intent.barberName != null && intent.barberName!.isNotEmpty) {
        // AI'dan salon adı geldi, bunu kullan
        final barbersSnapshot = await FirebaseFirestore.instance
            .collection('barbers')
            .get();
        
        if (barbersSnapshot.docs.isEmpty) {
          setState(() {
            _messages.add(ChatMessage.assistant(
              '❌ Sistemde kayıtlı berber bulunamadı. Lütfen daha sonra tekrar deneyin.',
            ));
          });
          return;
        }
        
        // Salon adına göre berberi bul (case-insensitive)
        final targetName = intent.barberName!.toLowerCase().trim();

        // Önce salon adına karşılık gelen sabit e-postaya sahip gerçek berberi dene
        // (aynı adlı başka kayıtlar varsa yanlış berbere randevu gitmesin)
        final mappedEmail = SalonNameHelper.getEmailFromSalonName(intent.barberName);
        if (mappedEmail != null) {
          for (var doc in barbersSnapshot.docs) {
            final email = (doc.data()['email'] as String?)?.toLowerCase().trim();
            if (email == mappedEmail) {
              barberId = doc.id;
              break;
            }
          }
        }

        for (var doc in barbersSnapshot.docs) {
          if (barberId != null) break;
          final data = doc.data();
          final salonName = (data['salonName'] as String?)?.toLowerCase().trim() ?? '';
          
          // Tam eşleşme veya kısmi eşleşme kontrol et
          if (salonName == targetName || 
              salonName.contains(targetName) || 
              targetName.contains(salonName)) {
            barberId = doc.id;
            break;
          }
        }
        
        // Eşleşme bulunamadıysa ilk berberi kullan
        if (barberId == null) {
          barberId = barbersSnapshot.docs.first.id;
          print('Salon eşleşmedi: ${intent.barberName}, ilk berber kullanılıyor: $barberId');
        }
      } else {
        // Salon adı belirtilmemişse ilk berberi al
        final barbersSnapshot = await FirebaseFirestore.instance
            .collection('barbers')
            .limit(1)
            .get();
        
        if (barbersSnapshot.docs.isEmpty) {
          setState(() {
            _messages.add(ChatMessage.assistant(
              '❌ Sistemde kayıtlı berber bulunamadı. Lütfen daha sonra tekrar deneyin.',
            ));
          });
          return;
        }
        
        barberId = barbersSnapshot.docs.first.id;
      }
      
      // Tarih parse et
      DateTime date;
      try {
        if (intent.date!.contains('/')) {
          // DD/MM/YYYY formatı
          final parts = intent.date!.split('/');
          if (parts.length != 3) {
            throw Exception('Geçersiz tarih formatı');
          }
          date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else if (intent.date!.contains('-')) {
          // YYYY-MM-DD formatı (ISO)
          date = DateTime.parse(intent.date!);
        } else {
          throw Exception('Geçersiz tarih formatı');
        }
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage.assistant(
            '❌ Tarih formatı hatalı. Lütfen geçerli bir tarih girin.',
          ));
        });
        return;
      }

      await AppointmentService().createAppointment(
        barberId: barberId,
        customerId: user.uid,
        date: date,
        time: intent.time!,
        customerName: intent.customerName ?? 'Müşteri',
        customerPhone: intent.customerPhone ?? '',
      );

      setState(() {
        _messages.add(ChatMessage.assistant(
          '✅ Randevunuz başarıyla oluşturuldu!\n\n📅 ${intent.date} - ${intent.time}\n\n✨ Randevunuz onay bekliyor. Berber onayladığında bildirim alacaksınız.',
        ));
      });
    } catch (e) {
      // Hata mesajını kullanıcı dostu hale getir
      String userMessage;
      
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('dolu') || 
          errorString.contains('çakış') || 
          errorString.contains('conflict') ||
          errorString.contains('zaten var')) {
        // Çakışma hatası
        userMessage = '''❌ Üzgünüm, seçtiğiniz saat dolu!

📅 ${intent.date} - ${intent.time}

Lütfen farklı bir saat seçin. Size uygun başka bir saat önerebilir miyim?''';
      } else if (errorString.contains('geçmiş') || 
                 errorString.contains('past') ||
                 errorString.contains('eski')) {
        // Geçmiş tarih hatası
        userMessage = '❌ Geçmiş bir tarihe randevu oluşturulamaz. Lütfen bugün veya gelecek bir tarih seçin.';
      } else if (errorString.contains('pazar') || errorString.contains('sunday')) {
        // Pazar günü hatası
        userMessage = '❌ Üzgünüm, Pazar günleri salonlarımız kapalıdır. Pazartesi-Cumartesi arası randevu alabilirsiniz.';
      } else if (errorString.contains('permission') || 
                 errorString.contains('izin') ||
                 errorString.contains('yetkisiz')) {
        // Yetki hatası
        userMessage = '❌ Randevu oluşturma yetkiniz yok. Lütfen giriş yapın.';
      } else {
        // Genel hata
        userMessage = '''❌ Randevunuz oluşturulamadı.

Lütfen bilgilerinizi kontrol edip tekrar deneyin veya farklı bir saat seçin.''';
      }
      
      setState(() {
        _messages.add(ChatMessage.assistant(userMessage));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Asistan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'KESTİRME Premium',
                    style: TextStyle(
                      color: const Color(0xFF00D4FF).withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_sweep,
                color: const Color(0xFFFF4757),
                shadows: [
                  Shadow(
                    color: const Color(0xFFFF4757).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              tooltip: 'Sohbeti Temizle',
              onPressed: () => _showClearChatDialog(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                key: ValueKey(_messages.length), // Force rebuild when list changes
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator();
                  }
                  
                  final msg = _messages[index];
                  
                  return _buildMessageBubble(msg.content, msg.isUser, index);
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: const Color(0xFF00D4FF).withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Mesajınızı yazın...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, int index) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF00FF88)])
              : null,
          color: isUser ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Asistan',
                      style: TextStyle(
                        color: const Color(0xFF00D4FF).withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * (index % 5))).slideY(begin: 0.1);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 6),
            _buildDot(1),
            const SizedBox(width: 6),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat())
      .fadeIn(delay: Duration(milliseconds: 200 * index))
      .fadeOut(delay: const Duration(milliseconds: 400));
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: const Color(0xFFFF4757).withOpacity(0.3), width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cleaning_services, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Sohbeti Temizle', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm mesajları silmek istediğinizden emin misiniz?',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF00D4FF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_messages.length} mesaj silinecek',
                      style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.white70)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _clearChat();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Temizle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _clearChat() {
    // Önce listeyi tamamen boşalt
    _messages.clear();
    
    // setState ile UI'yi zorla güncelle
    setState(() {
      // Listeyi boşaltıp tekrar welcome mesajı ekle
      _addWelcomeMessage();
    });
    
    // Scroll'u en üste al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Sohbet temizlendi (${_messages.length} mesaj)'),
          ],
        ),
        backgroundColor: const Color(0xFF00FF88),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
