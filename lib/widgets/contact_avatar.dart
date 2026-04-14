import 'package:flutter/material.dart';

class ContactAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? photoUri;
  final String? heroTag;

  const ContactAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.photoUri,
    this.heroTag,
  });

  static const List<Color> _palette = [
    Color(0xFF1A73E8),
    Color(0xFF34A853),
    Color(0xFFFBBC04),
    Color(0xFFEA4335),
    Color(0xFF8430CE),
    Color(0xFF00897B),
    Color(0xFFE91E63),
    Color(0xFFFF6D00),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorIndex = name.hashCode.abs() % _palette.length;
    final color = _palette[colorIndex];

    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      initials = parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();
    }
    if (initials.isEmpty) initials = '#';

    Widget avatar;

    if (photoUri != null && photoUri!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUri!),
        backgroundColor: color.withValues(alpha: isDark ? 0.3 : 0.15),
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: isDark ? 0.25 : 0.12),
        child: Text(
          initials,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: radius * 0.7,
          ),
        ),
      );
    }

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: avatar,
      );
    }

    return avatar;
  }
}

