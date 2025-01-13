import 'package:flutter/material.dart';
import '../globals.dart' as globals;
import '../widgets/text.dart'; // CustomText widget
import '../colors.dart';

/// Display daily suggestions according to a certain day's goal progress metrics.
/// Depending on which goal area underperformed, suggestions are updated
class DailySuggestions extends StatelessWidget {
  const DailySuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    // Dynamic suggestion generation
    final suggestions = globals.newDay
        ? [
      "Exercise More!",
      "Eat Healthier!"
    ]
        : [
      "Drink More Water!",
      "Exercise More!",
      "Eat Healthier!"
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Background color for the card
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and divider
            CustomText(
              text: "Daily Suggestions",
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: CustomColors.darkGray,
              squash: true,
            ),
            const SizedBox(height: 5.0),
            const Divider(
              thickness: 1.0,
              color: CustomColors.lightGray, // Divider color
            ),
            const SizedBox(height: 10.0),
            // Suggestions list
            Column(
              children: suggestions.expand((suggestion) {
                return [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/checkmark.png', // Checkmark icon
                        width: 20.0,
                        height: 20.0,
                      ),
                      const SizedBox(width: 10.0),
                      CustomText(
                        text: suggestion, // Suggestion text
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: CustomColors.darkGray,
                        squash: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5.0), // Space between suggestions
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
