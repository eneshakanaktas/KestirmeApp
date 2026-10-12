import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'pages/splash_page.dart';
import 'pages/auth_selection_page.dart';
import 'pages/customer_auth_page.dart';
import 'pages/barber_auth_page.dart';
import 'pages/auth_gate_page.dart';
import 'pages/customer_home_page.dart';
import 'pages/barber_home_page.dart';
import 'pages/ai_chat_page.dart';
import 'pages/change_password_page.dart';

/// Uygulamanın giriş noktası
/// Firebase ve environment variables initialize edildikten sonra Splash açılır
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Environment variables yükle (.env dosyası)
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    print('Warning: .env dosyası yüklenemedi: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kestirme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          background: const Color(0xFF0F0F0F), // Derin siyah
          surface: const Color(0xFF1A1A1A), // Kart arka planı
          primary: const Color(0xFF00D4FF), // Turkuaz accent
          secondary: const Color(0xFFFFD700), // Altın detay
          onBackground: Colors.white,
          onSurface: const Color(0xFFE0E0E0),
          primaryContainer: const Color(0xFF00D4FF).withOpacity(0.2),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),  // Daha derin siyah
        // Sayfa geçiş animasyonları
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        // Premium fontlar
        textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFFE0E0E0),
          ),
          bodyMedium: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        // Kart teması - Glassmorphism
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A).withOpacity(0.6),  // Semi-transparent
          elevation: 0,  // Glassmorphism için elevation kaldırıldu
          shadowColor: const Color(0xFF00D4FF).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),  // 20px rounded
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),  // Glassmorphism border
              width: 1,
            ),
          ),
        ),
        // AppBar teması
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Buton teması - Premium
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),  // Rounded buton
            ),
            elevation: 0,
            shadowColor: const Color(0xFF00D4FF).withOpacity(0.5),
          ),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
      // Başlangıç rotası
      initialRoute: '/splash',
      // Rotalar
      routes: {
        '/splash': (context) => const SplashPage(),
        '/auth-selection': (context) => const AuthSelectionPage(),
        '/customer-auth': (context) => const CustomerAuthPage(),
        '/barber-auth': (context) => const BarberAuthPage(),
        '/auth-gate': (context) => const AuthGatePage(),
        '/customer-home': (context) => const CustomerHomePage(),
        '/barber-home': (context) => const BarberHomePage(),
        '/ai-chat': (context) => const AiChatPage(),
        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }
}
