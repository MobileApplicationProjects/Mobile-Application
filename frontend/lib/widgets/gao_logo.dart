import 'package:flutter/material.dart';

class GaoLogo extends StatelessWidget {
  final double size;

  const GaoLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/gao_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
