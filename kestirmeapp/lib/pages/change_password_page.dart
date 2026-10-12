import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Password Change Page
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Kullanıcı bulunamadı');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre başarıyla güncellendi!'), backgroundColor: Color(0xFF00FF88)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String message = 'Hata oluştu';
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') message = 'Mevcut şifre yanlış';
        if (e.code == 'weak-password') message = 'Yeni şifre çok zayıf';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          title: const Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.lock_reset, size: 48, color: Color(0xFF00D4FF)),
                  ).animate().scale(),
                  const SizedBox(height: 32),
                  
                  _buildGlassField(
                    controller: _currentPasswordController,
                    label: 'Mevcut Şifre',
                    obscure: _obscureCurrent,
                    onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassField(
                    controller: _newPasswordController,
                    label: 'Yeni Şifre',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (v) => (v?.length ?? 0) < 6 ? 'En az 6 karakter' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildGlassField(
                    controller: _confirmPasswordController,
                    label: 'Yeni Şifre (Tekrar)',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) => v != _newPasswordController.text ? 'Şifreler eşleşmiyor' : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF00FF88)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Şifreyi Güncelle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.5)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white.withOpacity(0.5)),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
