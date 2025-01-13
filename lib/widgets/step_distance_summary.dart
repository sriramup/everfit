import 'package:flutter/material.dart';
import '../colors.dart';
import '../widgets/text.dart';

/// Displays the step count and distance traveled for the day,
/// alongside comparison indicators for previous data.
class StepDistanceCard extends StatelessWidget {
  final int steps; // Total steps for the day
  final int stepDifference; // Difference in step count compared to the previous period
  final double distance; // Total distance walked or run (in miles)
  final double distanceDifference; // Difference in distance compared to the previous period
  final bool? stepsIncOrDec; // Indicator for increase (true) or decrease (false) in steps
  final bool? distanceIncOrDec; // Indicator for increase (true) or decrease (false) in distance

  const StepDistanceCard({
    super.key,
    required this.steps,
    required this.stepDifference,
    required this.distance,
    required this.distanceDifference,
    this.stepsIncOrDec,
    this.distanceIncOrDec,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step Count Column
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
              ),
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  CustomText(
                    text: "Step Count",
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.darkGray,
                    squash: true,
                  ),
                  const SizedBox(height: 5.0),
                  // Step count value
                  CustomText(
                    text: "$steps",
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.primary,
                    squash: true,
                    textHeight: 0.8,
                  ),
                  const SizedBox(height: 10.0),
                  // Step difference indicator
                  Row(
                    children: [
                      Icon(
                        stepsIncOrDec != null && stepsIncOrDec!
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: stepsIncOrDec != null && stepsIncOrDec!
                            ? Colors.red
                            : Colors.blue,
                        size: 20.0,
                      ),
                      const SizedBox(width: 5.0),
                      CustomText(
                        text: "${stepsIncOrDec != null && stepsIncOrDec! ? 'Up' : 'Down'} $stepDifference",
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: stepsIncOrDec != null && stepsIncOrDec!
                            ? Colors.red
                            : Colors.blue,
                        squash: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5.0),
          // Step Distance Column
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
              ),
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  CustomText(
                    text: "Step Distance",
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.darkGray,
                    squash: true,
                  ),
                  const SizedBox(height: 5.0),
                  // Distance value
                  CustomText(
                    text: "${distance.toStringAsFixed(1)} MI",
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.primary,
                    textHeight: 0.8,
                    squash: true,
                  ),
                  const SizedBox(height: 10.0),
                  // Distance difference indicator
                  Row(
                    children: [
                      Icon(
                        distanceIncOrDec != null && distanceIncOrDec!
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: distanceIncOrDec != null && distanceIncOrDec!
                            ? Colors.red
                            : Colors.blue,
                        size: 20.0,
                      ),
                      const SizedBox(width: 5.0),
                      // Up or down arrow logic similar to CalorieSummaryCard
                      CustomText(
                        text: "${distanceIncOrDec != null && distanceIncOrDec! ? 'Up' : 'Down'} ${distanceDifference.toStringAsFixed(1)}",
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: distanceIncOrDec != null && distanceIncOrDec!
                            ? Colors.red
                            : Colors.blue,
                        squash: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
