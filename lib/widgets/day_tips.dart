import 'package:flutter/material.dart';
import '../globals.dart' as globals;
import '../widgets/text.dart'; // CustomText widget
import '../colors.dart';

class DayTips extends StatelessWidget {
  final bool sunny;

  const DayTips({super.key, required this.sunny});

  @override
  Widget build(BuildContext context) {
    // Define the suggestions
    final tipsAndExplanations = sunny
        ? [
      {
        "tip": "Stay Hydrated: ",
        "explanation": "Bring plenty of water for your sessions",
      },
      {
        "tip": "Use Sunscreen: ",
        "explanation": "Protect your skin with SPF 30+",
      },
      {
        "tip": "Plan a Time: ",
        "explanation":
        "Exercise in the morning or evening to avoid the peak midday heat",
      },
      {
        "tip": "Dress Properly: ",
        "explanation":
        "Choose breathable clothing and comfortable shoes",
      },
    ]
        : [
      {
        "tip": "Layer Up: ",
        "explanation": "Wear multiple layers of clothing",
        "explanation2": "to keep warm",
      },
      {
        "tip": "Stay Hydrated: ",
        "explanation":
        "Even in the cold, bodies",
        "explanation2": "lose moisture, so drink plenty of water!",
      },
      {
        "tip": "Eat Warming Foods: ",
        "explanation":
        "Eat foods like soups,",
        "explanation2": "stews, and cereals that provide warmth",
      },
      {
        "tip": "Keep Active Indoors: ",
        "explanation":
        "If it's too cold to go",
        "explanation2": "outside, choose indoor activities like yoga",
        "explanation3": "or stretching to stay energized",
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 00.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and divider
            CustomText(
              text: sunny ? 'Sunny Day Tips' : 'Chilly Day Tips',
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: CustomColors.darkGray,
              squash: true,
            ),
            const SizedBox(height: 5.0),
            const Divider(
              thickness: 1.0,
              color: CustomColors.lightGray,
            ),
            const SizedBox(height: 10.0),
            // Suggestions list
            Column(
              children: tipsAndExplanations.expand((tip) {
                return [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/checkmark.png', // Path to checkmark icon
                        width: 20.0,
                        height: 20.0,
                      ),
                      const SizedBox(width: 10.0),
                      CustomText(
                        text: tip["tip"] ?? "",
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.darkGray,
                        squash: true,
                      ),
                      CustomText(
                        text: tip["explanation"] ?? "",
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: CustomColors.primary,
                        squash: true,
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 30.0),
                      CustomText(
                        text: tip["explanation2"] ?? "",
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: CustomColors.primary,
                        squash: true,
                      ),
                    ],
                  ),
                  if (tip["explanation3"] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 30.0),
                        CustomText(
                          text: tip["explanation3"] ?? "",
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: CustomColors.primary,
                          squash: true,
                        ),
                      ],
                    ),
                  SizedBox(height: 15),
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
