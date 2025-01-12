import 'package:flutter/material.dart';
import '../colors.dart';


class CustomButton extends StatelessWidget {
  final String text; // Text for the button
  final VoidCallback onPressed; // Callback for button press
  final Color backgroundColor; // Background color of the button
  final Color textColor; // Text color
  final double? textSize;


  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    this.textColor = CustomColors.black,
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.0), // Use the provided padding
      child: FractionallySizedBox(
        widthFactor: 1.0, // Button width relative to its container's width
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: backgroundColor, // Button background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9.0), // Rounded corners
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0), // Internal button padding
          ),
          onPressed: onPressed,
          child: Transform(
            transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins', // Use Poppins font
                fontSize: textSize ?? 16, // Adjust font size
                fontWeight: FontWeight.w600, // Font weight
                color: textColor, // Text color
                letterSpacing: -0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}