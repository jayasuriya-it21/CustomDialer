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

    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.35 : 0.18),
            color.withValues(alpha: isDark ? 0.15 : 0.06),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
        image: photoUri != null && photoUri!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(photoUri!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUri == null || photoUri!.isEmpty
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: isDark ? color.withValues(alpha: 0.95) : color,
                  fontWeight: FontWeight.w600,
                  fontSize: radius * 0.72,
                  letterSpacing: -0.2,
                ),
              ),
            )
          : null,
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: avatar,
      );
    }

    return avatar;
  }
}

