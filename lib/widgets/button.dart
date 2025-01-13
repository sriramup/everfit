import 'package:flutter/material.dart';
import '../colors.dart';

/// A reusable custom button with configurable text, colors, and actions.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed; // Perform an action when the button is pressed
  final Color backgroundColor;
  final Color textColor;
  final double? textSize; // Optional font size for the button text

  /// Constructor for the `CustomButton` widget.
  const CustomButton({
    super.key,
    required this.text, // Button text is mandatory
    required this.onPressed, // onPressed callback is mandatory
    required this.backgroundColor, // Background color is mandatory
    this.textColor = CustomColors.black, // Default text color is black
    this.textSize, // Optional text size
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Add horizontal padding around the button
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: FractionallySizedBox(
        widthFactor: 1.0, // Make the button take full width of its container
        child: ElevatedButton(
          // Button styling
          style: ElevatedButton.styleFrom(
            elevation: 0, // Remove button shadow
            backgroundColor: backgroundColor, // Set background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9.0), // Rounded corners
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0), // Button height
          ),
          onPressed: onPressed, // Execute the callback on button press
          child: Transform(
            // Slightly squash the button text vertically
            transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0),
            child: Text(
              text, // Display the button text
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: textSize ?? 16, // Default to 16 if no size is provided
                fontWeight: FontWeight.w600, // Bold the text slightly
                color: textColor,
                letterSpacing: -0.7, // Adjust letter spacing for better readability
              ),
            ),
          ),
        ),
      ),
    );
  }
}