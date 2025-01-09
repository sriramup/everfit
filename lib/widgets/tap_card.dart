import 'package:flutter/material.dart';
import '../colors.dart';

class TapCard extends StatelessWidget {
  final String text; // Main text for the card
  final String imagePath; // Path for the rounded image icon
  final String? subText; // Optional subtext
  final VoidCallback onPressed; // Callback for card press
  final Color backgroundColor; // Background color of the card
  final Color textColor; // Main text color
  final Color? subTextColor; // Subtext color
  final Color? border; // Optional border color for the image
  final Color? imageColor; // Optional color for the image
  final Color? containerColor;

  const TapCard({
    super.key,
    required this.text,
    required this.imagePath,
    required this.onPressed,
    this.subText,
    required this.backgroundColor,
    this.textColor = CustomColors.darkGray,
    this.subTextColor = CustomColors.gray,
    this.border,
    this.imageColor, // Initialize the optional parameter
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: backgroundColor == CustomColors.offWhite || containerColor == CustomColors.turqoise ? const EdgeInsets.symmetric(horizontal: 0.0) : const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: onPressed, // Handle the tap
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rounded Image Icon with conditional border
              Padding(
                padding: const EdgeInsets.only(right: 10.0, left: 5.0),
                // Add padding around the image
                child: Container(
                  width: 50.0, // Larger image width
                  height: 50.0, // Larger image height
                  decoration: BoxDecoration(
                    color: backgroundColor == CustomColors.offWhite ? CustomColors.primary : containerColor != null ? CustomColors.turqoise : null,
                    borderRadius: BorderRadius.circular(8.0),
                    border: border != null
                        ? Border.all(
                      color: border!,
                      width: 2.0,
                    )
                        : null, // Add border only if provided
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: backgroundColor == CustomColors.offWhite ? EdgeInsets.all(10.0) : containerColor == CustomColors.turqoise ? EdgeInsets.all(1.0) : null,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        color: imageColor, // Apply the imageColor if provided
                        colorBlendMode: imageColor != null
                            ? BlendMode.srcIn
                            : BlendMode.dst, // Ensure proper blending
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 24.0,
                        ), // Fallback icon if image fails to load
                      ),
                    ),
                  ),
                ),
              ),
              // Text Column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  // Add padding for the text
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform(
                        transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      if (subText != null)
                      // Add space between text and subtext
                        Transform(
                          transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0),
                          child: Text(
                            subText!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Custom Arrow Icon
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                // Add spacing before the arrow
                child: Image.asset(
                  'assets/images/arrow.png',
                  // Replace with your actual arrow image path
                  width: 16.0,
                  height: 16.0,
                  color: CustomColors.gray, // Gray color for the arrow
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
