import 'package:flutter/material.dart';
import '../colors.dart'; // Custom colors
import '../widgets/text.dart'; // CustomText widget

class MiniInfo extends StatelessWidget {
  final String text;

  const MiniInfo({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Center(
        child: CustomText(
          text: text,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: CustomColors.darkGray,
          squash: true,
        ),
      ),
    );
  }
}
