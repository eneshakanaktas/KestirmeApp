import 'package:flutter/material.dart';
import 'dart:ui';

/// Ultra Premium Card - Glassmorphism + Glow + Hover efektleri
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? glowColor;
  final bool enableHover;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.glowColor,
    this.enableHover = true,
    this.onTap,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? const Color(0xFF00D4FF);
    
    return MouseRegion(
      onEnter: widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
          transform: _isHovered 
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 20 : 10,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: glowColor.withOpacity(_isHovered ? 0.5 : 0.2),
                    width: 1.5,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Status Badge
class PremiumStatusBadge extends StatelessWidget {
  final String status;
  final String label;
  
  const PremiumStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFD700);
      case 'approved':
        return const Color(0xFF00FF88);
      case 'completed':
        return const Color(0xFF00D4FF);
      case 'cancelled':
        return const Color(0xFFFF4757);
      default:
        return Colors.grey;
    }
  }
}

/// Barber themed icons
class BarberIcons {
  static const IconData scissors = Icons.content_cut;
  static const IconData razor = Icons.face_retouching_natural;
  static const IconData comb = Icons.brush;
  static const IconData chair = Icons.chair;
  static const IconData mirror = Icons.person;
  static const IconData appointment = Icons.calendar_month;
  static const IconData time = Icons.schedule;
  static const IconData phone = Icons.phone;
  static const IconData location = Icons.location_on;
  static const IconData notification = Icons.notifications;
  static const IconData chat = Icons.chat_bubble;
  static const IconData history = Icons.history;
  static const IconData settings = Icons.settings;
  static const IconData logout = Icons.logout;
}
