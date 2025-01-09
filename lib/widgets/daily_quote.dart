import 'package:flutter/material.dart';
import '../globals.dart' as globals;

class DailyQuote extends StatelessWidget {
  final String dayOne; // Image path for day one
  final String dayTwo; // Image path for day two

  const DailyQuote({
    super.key,
    required this.dayOne,
    required this.dayTwo,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which image to show based on globals.newDay
    final imagePath = globals.newDay ? dayTwo : dayOne;

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Image.asset(
            imagePath, // Use the determined image path
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
