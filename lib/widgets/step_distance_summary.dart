import 'package:flutter/material.dart';
import '../colors.dart';
import '../widgets/text.dart';

class StepDistanceCard extends StatelessWidget {
  final int steps; // Step count
  final int stepDifference; // Difference for step count
  final double distance; // Distance walked or run
  final double distanceDifference; // Difference for distance
  final bool? stepsIncOrDec; // If the arrow indicates an increase or decrease for steps
  final bool? distanceIncOrDec; // If the arrow indicates an increase or decrease for distance

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
                  CustomText(
                    text: "Step Count",
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.darkGray,
                    squash: true,
                  ),
                  const SizedBox(height: 5.0),
                  CustomText(
                    text: "$steps",
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.primary,
                    squash: true,
                    textHeight: 0.8,
                  ),
                  const SizedBox(height: 10.0),
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
                        text:
                        "${stepsIncOrDec != null && stepsIncOrDec! ? 'Up' : 'Down'} $stepDifference",
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
                  CustomText(
                    text: "Step Distance",
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.darkGray,
                    squash: true,
                  ),
                  const SizedBox(height: 5.0),
                  CustomText(
                    text: "${distance.toStringAsFixed(1)} MI",
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.primary,
                    textHeight: 0.8,
                    squash: true,
                  ),
                  const SizedBox(height: 10.0),
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
                      CustomText(
                        text:
                        "${distanceIncOrDec != null && distanceIncOrDec! ? 'Up' : 'Down'} ${distanceDifference.toStringAsFixed(1)}",
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
