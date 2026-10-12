import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Customer Appointment Creation Page
class CustomerCreateAppointmentPage extends StatefulWidget {
  final String barberId;
  
  const CustomerCreateAppointmentPage({
    super.key,
    required this.barberId,
  });

  @override
  State<CustomerCreateAppointmentPage> createState() =>
      _CustomerCreateAppointmentPageState();
}

class _CustomerCreateAppointmentPageState
    extends State<CustomerCreateAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static const List<String> _availableTimeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
    '21:00', '21:30', '22:00', '22:30', '23:00', '23:30',
    '00:00',
  ];

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'İsim gerekli';
    if (value.trim().length < 3) return 'En az 3 karakter';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Telefon numarası gerekli';
    if (value.length != 10) return '10 hane olmalı';
    return null;
  }

  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF00D4FF),
              onPrimary: Colors.black,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
      selectableDayPredicate: (date) => date.weekday != DateTime.sunday,
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
        title: const Text('Saat Seçin', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _availableTimeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = _availableTimeSlots[index];
              final isSelected = timeSlot == _selectedTime;
              return ListTile(
                title: Text(
                  timeSlot,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF00D4FF) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () => Navigator.pop(context, timeSlot),
              );
            },
          ),
        ),
      ),
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Lütfen tarih seçin');
      return;
    }
    if (_selectedTime == null) {
      _showError('Lütfen saat seçin');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Giriş yapmanız gerekiyor');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _appointmentService.createAppointment(
        customerId: user.uid,
        barberId: widget.barberId,
        date: _selectedDate!,
        time: _selectedTime!,
        customerName: _nameController.text.trim(),
        customerPhone: '+90${_phoneController.text.trim()}',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu oluşturuldu!'), backgroundColor: Color(0xFF00FF88)),
      );
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Randevu Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Müşteri Bilgileri', Icons.person),
                const SizedBox(height: 16),
                _buildGlassTextField(
                  controller: _nameController,
                  label: 'İsim Soyisim',
                  icon: Icons.person_outline,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                _buildGlassTextField(
                  controller: _phoneController,
                  label: 'Telefon Numarası',
                  icon: Icons.phone_outlined,
                  prefixText: '+90 ',
                  keyboardType: TextInputType.phone,
                  formatter: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validatePhone,
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Randevu Zamanı', Icons.access_time),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionCard(
                        icon: Icons.calendar_month,
                        title: 'Tarih',
                        value: _selectedDate == null 
                            ? 'Seçiniz' 
                            : DateFormat('dd MMM', 'tr_TR').format(_selectedDate!),
                        onTap: _selectDate,
                        isActive: _selectedDate != null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSelectionCard(
                        icon: Icons.schedule,
                        title: 'Saat',
                        value: _selectedTime ?? 'Seçiniz',
                        onTap: _selectTime,
                        isActive: _selectedTime != null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Randevuyu Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D4FF), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatter,
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
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        inputFormatters: formatter,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF00D4FF).withOpacity(0.1) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? const Color(0xFF00D4FF).withOpacity(0.5) 
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF00D4FF) : Colors.white.withOpacity(0.5),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
