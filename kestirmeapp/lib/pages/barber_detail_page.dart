import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/barber_service.dart';
import '../models/barber.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ultra Premium Berber Detay Sayfası
class BarberDetailPage extends StatefulWidget {
  final String barberId;
  final String salonName;

  const BarberDetailPage({
    super.key,
    required this.barberId,
    required this.salonName,
  });

  @override
  State<BarberDetailPage> createState() => _BarberDetailPageState();
}

class _BarberDetailPageState extends State<BarberDetailPage> {
  final _barberService = BarberService();
  Barber? _barber;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarberDetails();
  }

  Future<void> _loadBarberDetails() async {
    try {
      final barberMap = await _barberService.getBarberById(widget.barberId);
      if (mounted) {
        setState(() {
          if (barberMap != null) {
            _barber = Barber.fromMap(barberMap, widget.barberId);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnimatedPremiumBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
        ),
      );
    }

    if (_barber == null) {
      return const Scaffold(body: Center(child: Text('Berber bulunamadı')));
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.barberId;

    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          actions: [
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFFFFD700)),
                onPressed: () => Navigator.pushNamed(context, '/barber-home/edit-profile'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo/Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.salonName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().scale(),

              const SizedBox(height: 16),

              Text(
                widget.salonName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 8),

              RatingBarIndicator(
                rating: _barber!.averageRating,
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                ),
                itemCount: 5,
                itemSize: 20.0,
                unratedColor: Colors.white.withOpacity(0.3),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              _buildInfoCard(
                icon: Icons.location_on,
                label: 'Adres',
                value: _barber!.address,
                color: const Color(0xFF00D4FF),
              ).animate().fadeIn(delay: 100.ms).slideX(),

              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.phone,
                label: 'Telefon',
                value: _barber!.phone,
                color: const Color(0xFF00FF88),
              ).animate().fadeIn(delay: 200.ms).slideX(),

              const SizedBox(height: 32),

              if (!isOwner)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Appointment logic would go here, usually handled in home page flow
                      Navigator.pop(context); // Or navigate to booking
                    },
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'RANDEVU AL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
