import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Berber Profili Düzenleme Sayfası
class BarberEditProfilePage extends StatefulWidget {
  const BarberEditProfilePage({super.key});

  @override
  State<BarberEditProfilePage> createState() => _BarberEditProfilePageState();
}

class _BarberEditProfilePageState extends State<BarberEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _salonNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _salonNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        _salonNameController.text = data['salonName'] as String? ?? '';
        _phoneController.text = data['phone'] as String? ?? '';
        _addressController.text = data['address'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('[PROFILE_LOAD_ERROR] $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('barbers')
          .doc(user.uid)
          .update({
        'salonName': _salonNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Salon bilgileri güncellendi'),
            backgroundColor: Color(0xFF00FF88),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[PROFILE_SAVE_ERROR] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4757),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnimatedPremiumBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          ),
        ),
      );
    }

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
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Profil Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF00D4FF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bu bilgiler müşterilere gösterilir',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(),

                const SizedBox(height: 32),

                _buildPremiumTextField(
                  controller: _salonNameController,
                  label: 'Salon Adı',
                  icon: Icons.store,
                  hint: 'Örn: Gold Makas',
                  validator: (v) => v!.isEmpty ? 'Salon adı gerekli' : null,
                ).animate().fadeIn(delay: 100.ms).slideY(),

                const SizedBox(height: 20),

                _buildPremiumTextField(
                  controller: _phoneController,
                  label: 'Telefon',
                  icon: Icons.phone,
                  hint: '05XX XXX XX XX',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Telefon gerekli' : null,
                ).animate().fadeIn(delay: 200.ms).slideY(),

                const SizedBox(height: 20),

                _buildPremiumTextField(
                  controller: _addressController,
                  label: 'Adres',
                  icon: Icons.location_on,
                  hint: 'Tam adres giriniz',
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Adres gerekli' : null,
                ).animate().fadeIn(delay: 300.ms).slideY(),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'KAYDET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFFD700)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4757)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4757)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
