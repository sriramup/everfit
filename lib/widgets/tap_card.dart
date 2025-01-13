import 'package:flutter/material.dart';
import '../colors.dart';

/// A customizable card widget with an icon, main text, optional subtext, and a tap action.
///
/// [TapCard] is used for navigational purposes and supports dynamic styling,
/// optional subtext, and fallback behaviors for missing icons.
class TapCard extends StatelessWidget {
  /// The main text displayed on the card.
  final String text;

  /// The path to the image or icon displayed on the card.
  final String imagePath;

  /// Optional subtext displayed below the main text.
  final String? subText;

  /// The callback function triggered when the card is tapped.
  final VoidCallback onPressed;

  /// The background color of the card.
  final Color backgroundColor;

  /// The color of the main text.
  final Color textColor;

  /// The color of the subtext (if provided).
  final Color? subTextColor;

  /// An optional border color for the image/icon.
  final Color? border;

  /// An optional color to apply to the image/icon.
  final Color? imageColor;

  /// The background color of the image container.
  final Color? containerColor;

  /// An optional category to conditionally display specific icons.
  final String? category;

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
    this.imageColor,
    this.containerColor,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Conditional padding based on background or container color
      padding: backgroundColor == CustomColors.offWhite || containerColor == CustomColors.turquoise
          ? const EdgeInsets.symmetric(horizontal: 0.0)
          : const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: onPressed, // Trigger the callback on tap
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor, // Card background color
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: containerColor != null && containerColor == CustomColors.primaryFaded
              ? const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0)
              : const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rounded image or icon with optional border
              Padding(
                padding: const EdgeInsets.only(right: 10.0, left: 5.0),
                child: containerColor != null && containerColor == CustomColors.primaryFaded
                    ? CircleAvatar(
                  radius: 20.0,
                  backgroundColor: CustomColors.primaryFaded,
                  child: Icon(
                    _getCategoryIcon(category), // Icon based on category
                    color: CustomColors.primary,
                  ),
                )
                    : Container(
                  width: 50.0, // Image width
                  height: 50.0, // Image height
                  decoration: BoxDecoration(
                    color: backgroundColor == CustomColors.offWhite
                        ? CustomColors.primary
                        : containerColor,
                    borderRadius: BorderRadius.circular(8.0),
                    border: border != null
                        ? Border.all(
                      color: border!,
                      width: 2.0,
                    )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: backgroundColor == CustomColors.offWhite
                          ? const EdgeInsets.all(10.0)
                          : containerColor == CustomColors.turquoise
                          ? const EdgeInsets.all(1.0)
                          : null,
                      child: Image.asset(
                        imagePath, // Path to the image
                        fit: BoxFit.cover,
                        color: imageColor,
                        colorBlendMode: imageColor != null
                            ? BlendMode.srcIn
                            : BlendMode.dst,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Text column with main and subtext
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
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
              // Optional arrow icon for navigation
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Image.asset(
                  'assets/images/arrow.png', // Path to arrow image
                  width: 16.0,
                  height: 16.0,
                  color: CustomColors.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns an icon based on the provided [category].
  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'active':
        return Icons.local_fire_department;
      case 'nutrition':
        return Icons.no_food_rounded;
      case 'weight':
        return Icons.monitor_weight;
      case 'drink':
        return Icons.local_drink;
      case 'custom':
        return Icons.folder_special;
      default:
        return Icons.mode_night;
    }
  }
}

