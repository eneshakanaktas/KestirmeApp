import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'customer_home_page.dart';
import 'barber_home_page.dart';
import 'customer_auth_page.dart';

import 'auth_selection_page.dart';

/// GEÇİCİ (test): true iken "Müşteri" kartı otomatik misafir girişi yapar ve
/// berber giriş sayfasında "Misafir Berber" düğmesi görünür. Kapatmak için false yapın.
const bool kMisafirGirisiAcik = true;

/// Authentication Gate - Kullanıcı oturumunu dinleyen ve rolüne göre yönlendiren sayfa
/// Firebase authStateChanges() stream kullanarak gerçek zamanlı oturum takibi yapar
class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  /// Sabit berber email listesi (hardcoded)
  static const List<String> barberEmails = [
    'enes123@gmail.com',
    'rago@gmail.com',
    'hamza@gmail.com',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<User?>(
      // Firebase Auth oturum değişikliklerini dinle
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı durumu kontrol et
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading durumu
          return _buildLoadingScreen(theme, colorScheme, 'Bağlantı kuruluyor...');
        }

        // Kullanıcı oturum durumunu kontrol et
        final user = snapshot.data;

        if (user == null) {
          // Kullanıcı giriş yapmamış -> Seçim sayfasını göster
          debugPrint('AuthGate: Kullanıcı giriş yapmamış -> AuthSelectionPage');
          return const AuthSelectionPage();
        }

        debugPrint('AuthGate: Kullanıcı giriş yapmış - ${user.email}');
        
        // Misafir (anonim) kullanıcı: rolü e-postaya değil, barbers/{uid} kaydına göre belirle
        if (kMisafirGirisiAcik && user.isAnonymous) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('barbers').doc(user.uid).get(),
            builder: (context, barberSnap) {
              if (barberSnap.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen(theme, colorScheme, 'Bağlantı kuruluyor...');
              }
              final misafirBerber = barberSnap.data?.exists ?? false;
              return misafirBerber ? const BarberHomePage() : const CustomerHomePage();
            },
          );
        }

        // Kullanıcı giriş yapmış -> Rolünü kontrol et ve yönlendir
        return _buildRoleBasedNavigation(user, theme, colorScheme);
      },
    );
  }

  /// Loading ekranı widget'ı
  Widget _buildLoadingScreen(ThemeData theme, ColorScheme colorScheme, String message) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Yükleniyor mesajı
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kullanıcı rolüne göre yönlendirme yapan widget
  Widget _buildRoleBasedNavigation(
    User user,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // ÖNCELİK 1: Email bazlı rol kontrolü (hardcoded liste)
    final userEmail = user.email?.toLowerCase() ?? '';
    
    if (barberEmails.contains(userEmail)) {
      // Berber email listesinde var → Berber paneline yönlendir
      debugPrint('AuthGate: Email bazlı rol → Berber ($userEmail)');
      return const BarberHomePage();
    } else {
      // Berber listesinde yok → Müşteri paneline yönlendir
      debugPrint('AuthGate: Email bazlı rol → Müşteri ($userEmail)');
      return const CustomerHomePage();
    }

    // NOT: Firestore rol kontrolü kaldırıldı, artık sadece email bazlı kontrol var
  }

  /// Hata ekranı
  Widget _buildErrorScreen(
    ThemeData theme,
    ColorScheme colorScheme,
    String message,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rol bulunamadı ekranı
  Widget _buildNoRoleScreen(
    ThemeData theme,
    ColorScheme colorScheme,
    User user,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Kullanıcı Rolü Bulunamadı',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hesabınız için rol bilgisi bulunamadı.\nLütfen yönetici ile iletişime geçin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
