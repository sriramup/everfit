import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../colors.dart';
import '../widgets/text.dart';

/// A card widget displaying a summary of calories burned for the day, including a progress indicator and change details.
class CalorieSummaryCard extends StatelessWidget {
  final int caloriesBurned; // The number of calories burned today
  final int difference; // The difference in calories compared to the previous day
  final bool? incOrDec; // Indicates if the difference is an increase (true), decrease (false), or consistent (null)

  const CalorieSummaryCard({
    super.key,
    required this.caloriesBurned,
    required this.difference,
    this.incOrDec,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 25.0), // Padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and separator line
            CustomText(
              text: "Today's Move Summary",
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
            Row(
              children: [
                // Circular percent indicator for calories burned
                CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 20.0,
                  percent: (caloriesBurned / 300).clamp(0.0, 1.0), // Ensure percent is between 0 and 1
                  progressColor: CustomColors.primary,
                  backgroundColor: CustomColors.primaryFaded,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 15.0),
                // Calories burned text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: "Calories Burned",
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.darkGray,
                      squash: true,
                    ),
                    CustomText(
                      text: "$caloriesBurned/300", // Default goal
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.primary,
                      squash: true,
                    ),
                  ],
                ),
                const SizedBox(width: 20.0),
                // Comparison arrow and difference text in relation to previous day data
                if (incOrDec != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        incOrDec! ? Icons.arrow_upward : Icons.arrow_downward, // indicates positive or negative difference
                        color: incOrDec! ? Colors.red : Colors.blue, // Respective arrow colors
                        size: 30.0,
                      ),
                      CustomText(
                        text: "${incOrDec! ? 'Up' : 'Down'} $difference", // Difference text
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: incOrDec! ? Colors.red : Colors.blue,
                        squash: true,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
