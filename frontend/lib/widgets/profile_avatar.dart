import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Shared profile avatar widget.
/// Shows the user's avatar_url if available, or imageBytes for local preview,
/// otherwise a default grey person icon.
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final Uint8List? imageBytes;
  final double radius;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.imageBytes,
    this.radius = 32,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Local preview (priority)
    if (imageBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(imageBytes!),
        backgroundColor: backgroundColor ?? Colors.grey[800],
      );
    }

    // 2. Network URL
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: backgroundColor ?? Colors.grey[800],
        onBackgroundImageError: (_, __) {},
      );
    }

    // 3. Default fallback icon
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF333333),
      child: Icon(
        Icons.person,
        size: radius * 1.1,
        color: Colors.grey[400],
      ),
    );
  }
}
