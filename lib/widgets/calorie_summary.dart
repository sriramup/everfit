import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../colors.dart';
import '../widgets/text.dart';

class CalorieSummaryCard extends StatelessWidget {
  final int caloriesBurned; // Calories burned
  final int difference; // Difference for the arrow text
  final bool? incOrDec; // If the arrow indicates an increase, decrease, or a consistency

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
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 25.0), // Increased bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and separator line
            CustomText(
              text: "Today's Move Summary",
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: CustomColors.darkGray, squash: true,
            ),
            const SizedBox(height: 5.0),
            const Divider(
              thickness: 1.0,
              color: CustomColors.lightGray,
            ),
            const SizedBox(height: 10.0),
            // Circular progress and text
            Row(
              children: [
                // Circular percent indicator
                CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 20.0,
                  percent: caloriesBurned / 300,
                  progressColor: CustomColors.primary,
                  backgroundColor: CustomColors.primaryFaded,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(width: 15),
                // Calories text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: "Calories Burned",
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.darkGray, squash: true,
                    ),
                    CustomText(
                      text: "$caloriesBurned/300",
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.primary, squash: true,
                    ),
                  ],
                ),
                const SizedBox(width: 20.0),
                // Arrow and difference text
                if (incOrDec != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        incOrDec! ? Icons.arrow_upward : Icons.arrow_downward,
                        color: incOrDec! ? Colors.red : Colors.blue,
                        size: 30.0,
                      ),
                      CustomText(
                        text: "${incOrDec! ? 'Up' : 'Down'} $difference",
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
