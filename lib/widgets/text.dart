import 'package:flutter/material.dart';

/// Text formatting widget that provides a standard layout for all text displayed in the app
class CustomText extends StatelessWidget {
  final String text; // The text to display
  final double fontSize; // Font size of the text
  final FontWeight fontWeight; // Font weight of the text
  final Color color; // Color of the text
  final bool squash; // Whether to squash the text
  final TextAlign? textAlign; // Text alignment
  final String fontFamily; // Font family
  final double? textHeight;

  const CustomText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.squash,
    this.textHeight,
    this.textAlign,
    this.fontFamily = 'Poppins',
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: squash
          ? Matrix4.diagonal3Values(1.0, 0.95, 1.0) // Squash vertically
          : Matrix4.identity(),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.7, // Default letter spacing
          color: color,
          height: textHeight,
        ),
      ),
    );
  }
}
