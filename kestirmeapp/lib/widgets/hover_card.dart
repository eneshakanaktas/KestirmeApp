import 'package:flutter/material.dart';

/// Premium hover efekti widget'ı
/// Kartlara scale, glow ve shadow ekler
class HoverCard extends StatefulWidget {
  final Widget child;
  final double scaleAmount;
  final Color? glowColor;
  
  const HoverCard({
    super.key,
    required this.child,
    this.scaleAmount = 1.02,
    this.glowColor,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = widget.glowColor ?? theme.colorScheme.primary;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered 
            ? (Matrix4.identity()..scale(widget.scaleAmount))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          boxShadow: _isHovered ? [
            BoxShadow(
              color: glowColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Premium hover efekti olan buton wrapper
class HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  
  const HoverButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: _isPressed 
              ? (Matrix4.identity()..scale(0.95))
              : _isHovered
                  ? (Matrix4.identity()..scale(1.05))
                  : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}
