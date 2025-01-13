import 'package:flutter/material.dart';
import '../globals.dart' as globals;

/// Displays a daily quote image.
/// The image displayed rotates based on the value of `globals.newDay`.
class DailyQuote extends StatelessWidget {
  final String dayOne; // Image path for the first day's quote
  final String dayTwo; // Image path for the second day's quote

  const DailyQuote({
    super.key,
    required this.dayOne,
    required this.dayTwo,
  });

  @override
  Widget build(BuildContext context) {
    // Select the image based on the `globals.newDay` flag.
    final imagePath = globals.newDay ? dayTwo : dayOne;

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0), // Clip image to rounded corners
          child: Image.asset(
            imagePath, // Display the selected image
            fit: BoxFit.cover, // Ensure the image covers the container
          ),
        ),
      ),
    );
  }
}
