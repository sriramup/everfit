import 'package:flutter/material.dart';
import 'colors.dart'; // Your custom colors
import 'goals_page.dart';
import 'widgets/text.dart'; // Your CustomText widget
import 'globals.dart' as globals;

/// Creates a standard app bar layout for all main pages.
class CustomAppBar extends StatefulWidget {
  final String title; // The title of the AppBar
  final Widget body; // The body widget to display beneath the AppBar
  final bool subtitle; // Whether to display a subtitle (e.g., date)
  final bool add; // Whether to display an "add" button (for the goal page)

  const CustomAppBar({
    super.key,
    required this.title,
    required this.body,
    required this.subtitle,
    required this.add,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: CustomColors.offWhite, // Background color for the body
        child: CustomScrollView(
          slivers: [
            // Allows app bar to shrink as user scrolls
            SliverAppBar(
              pinned: true, // Keeps the AppBar visible when scrolling
              floating: false,
              expandedHeight: 110.0, // Height of the expanded AppBar
              backgroundColor: CustomColors.primary, // AppBar background color
              automaticallyImplyLeading: false, // Disable default back button
              actions: widget.add
                  ? [
                // Add button
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                          const AddGoalPage(), // Navigate to AddGoalPage
                        ),
                      );
                    },
                    child: Container(
                      width: 35.0,
                      height: 35.0,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: CustomColors.primary,
                        size: 25.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ]
                  : null, // Show or hide the Add button
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Determine if the AppBar is collapsed
                  bool isCollapsed =
                      constraints.biggest.height <= kToolbarHeight + 50;

                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero, // Remove padding for title
                    centerTitle: isCollapsed, // Center title when collapsed
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 0), // No delay
                      child: isCollapsed
                          ? Container(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Center(
                          child: CustomText(
                            key: const ValueKey('centeredTitle'),
                            text: widget.title,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            squash: true,
                          ),
                        ),
                      )
                          : Padding(
                        key: const ValueKey('leftAlignedTitle'),
                        padding: widget.subtitle
                            ? const EdgeInsets.only(left: 15, bottom: 8)
                            : const EdgeInsets.only(left: 15, bottom: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              text: widget.title,
                              fontSize: 35,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              squash: true,
                              textHeight: widget.subtitle ? 0.8 : null,
                            ),
                            if (widget.subtitle)
                              Padding(
                                padding:
                                const EdgeInsets.only(left: 2.0),
                                child: CustomText(
                                  text: globals.currentDate, // Dynamic subtitle
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  squash: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Main body content
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 0, // Minimum height of the body
                  maxHeight: double.infinity, // Prevent infinite height
                ),
                child: widget.body, // Inject the body widget
              ),
            ),
          ],
        ),
      ),
    );
  }
}
