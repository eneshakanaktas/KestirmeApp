import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/animated_premium_background.dart';
import '../widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Müşteri Giriş Sayfası
class CustomerAuthPage extends StatefulWidget {
  const CustomerAuthPage({super.key});

  @override
  State<CustomerAuthPage> createState() => _CustomerAuthPageState();
}

class _CustomerAuthPageState extends State<CustomerAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth-gate');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu email ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'email-already-in-use':
        return 'Bu email zaten kullanımda';
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'invalid-email':
        return 'Geçersiz email formatı';
      default:
        return 'Giriş başarısız: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ═══════════════════════════════════════════════════
                  // LOGO & TITLE
                  // ═══════════════════════════════════════════════════
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 50,
                      color: Colors.white,
                    ),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'KESTİRME',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _isLogin ? 'Müşteri Girişi' : 'Yeni Hesap Oluştur',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 48),
                  
                  // ═══════════════════════════════════════════════════
                  // FORM CARD
                  // ═══════════════════════════════════════════════════
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          _buildPremiumTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'ornek@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email gerekli';
                              }
                              if (!value.contains('@')) {
                                return 'Geçerli bir email girin';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Password Field
                          _buildPremiumTextField(
                            controller: _passwordController,
                            label: 'Şifre',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF00D4FF),
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          
                          // Confirm Password (only for signup)
                          if (!_isLogin) ...[
                            const SizedBox(height: 20),
                            _buildPremiumTextField(
                              controller: _confirmPasswordController,
                              label: 'Şifre Tekrar',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF00D4FF),
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirm = !_obscureConfirm);
                                },
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Şifreler eşleşmiyor';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          // Error Message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4FF).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isLogin ? Icons.login : Icons.person_add,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isLogin ? 'GİRİŞ YAP' : 'KAYIT OL',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Toggle Login/Signup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin ? 'Hesabınız yok mu?' : 'Zaten hesabınız var mı?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    _errorMessage = null;
                                  });
                                },
                                child: Text(
                                  _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                                  style: const TextStyle(
                                    color: Color(0xFF00D4FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Back to selection
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    label: Text(
                      'Geri Dön',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4FF)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF00D4FF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
