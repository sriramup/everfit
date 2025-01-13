import 'package:everfit/widgets/text.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino widgets
import 'package:flutter/material.dart';
import '../colors.dart';

/// Provides a layout for all IOS switches to be aesthetically displayed
class SliderCard extends StatefulWidget {
  final String text;
  final VoidCallback onActivate; // Callback for activation
  final VoidCallback onDeactivate; // Callback for deactivation
  bool isActive;

  SliderCard({
    super.key,
    required this.text,
    required this.onActivate,
    required this.onDeactivate,
    required this.isActive,
  });

  @override
  _SliderCardState createState() => _SliderCardState();
}

class _SliderCardState extends State<SliderCard> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left aligned text
          CustomText(
            text: widget.text,
            fontSize: 19,
            squash: true,
            fontWeight: FontWeight.w500,
            color: CustomColors.darkGray,
          ),
          // Right aligned CupertinoSwitch
          CupertinoSwitch(
            value: widget.isActive,
            onChanged: (value) {
              setState(() {
                widget.isActive = value; // Update the state
              });

              // Trigger the appropriate callback
              if (value) {
                widget.onActivate();
              } else {
                widget.onDeactivate();
              }
            },
            activeTrackColor: CustomColors.primary, // Customize active color
          ),
        ],
      ),
    );
  }
}
