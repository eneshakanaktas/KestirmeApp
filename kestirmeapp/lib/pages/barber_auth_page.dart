import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Berber Giriş Sayfası
class BarberAuthPage extends StatefulWidget {
  const BarberAuthPage({super.key});

  @override
  State<BarberAuthPage> createState() => _BarberAuthPageState();
}

class _BarberAuthPageState extends State<BarberAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
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
    _salonNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
        // Create user
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        // Save barber info to Firestore
        await FirebaseFirestore.instance.collection('barbers').doc(credential.user!.uid).set({
          'email': _emailController.text.trim(),
          'salonName': _salonNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
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
        return 'Bu email ile kayıtlı berber bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'email-already-in-use':
        return 'Bu email zaten kullanımda';
      case 'weak-password':
        return 'Şifre çok zayıf';
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
                  // BARBER LOGO
                  // ═══════════════════════════════════════════════════
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
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
                    'BERBER PANELİ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _isLogin ? 'Berber Girişi' : 'Salon Kaydı',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFFFFD700).withOpacity(0.8),
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 40),
                  
                  // ═══════════════════════════════════════════════════
                  // FORM CARD
                  // ═══════════════════════════════════════════════════
                  Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          _buildGoldTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'berber@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') 
                                ? 'Geçerli email girin' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Password
                          _buildGoldTextField(
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
                                color: const Color(0xFFFFD700),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => v != null && v.length < 6 
                                ? 'En az 6 karakter' : null,
                          ),
                          
                          // Signup extra fields
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            _buildGoldTextField(
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
                                  color: const Color(0xFFFFD700),
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) => v != _passwordController.text 
                                  ? 'Şifreler eşleşmiyor' : null,
                            ),
                            
                            const SizedBox(height: 24),
                            Divider(color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            
                            Text(
                              'SALON BİLGİLERİ',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: 12,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildGoldTextField(
                              controller: _salonNameController,
                              label: 'Salon Adı',
                              hint: 'Örn: Premium Berber',
                              icon: Icons.store,
                              validator: (v) => v == null || v.isEmpty 
                                  ? 'Salon adı gerekli' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildGoldTextField(
                              controller: _phoneController,
                              label: 'Telefon',
                              hint: '05XX XXX XX XX',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty 
                                  ? 'Telefon gerekli' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildGoldTextField(
                              controller: _addressController,
                              label: 'Adres',
                              hint: 'Salon adresi',
                              icon: Icons.location_on,
                              maxLines: 2,
                              validator: (v) => v == null || v.isEmpty 
                                  ? 'Adres gerekli' : null,
                            ),
                          ],
                          
                          // Error
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
                                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 28),
                          
                          // Submit Button - GOLD
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.4),
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
                                            _isLogin ? Icons.login : Icons.store,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isLogin ? 'GİRİŞ YAP' : 'SALON KAYDET',
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
                          
                          const SizedBox(height: 20),
                          
                          // Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin ? 'Salonunuz yok mu?' : 'Zaten kayıtlı mısınız?',
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                }),
                                child: Text(
                                  _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.bold,
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
                    .slideY(begin: 0.2),
                  
                  const SizedBox(height: 24),
                  
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.6)),
                    label: Text('Geri Dön', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
