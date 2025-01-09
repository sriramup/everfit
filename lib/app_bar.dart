import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'colors.dart'; // Your custom colors
import 'goals_page.dart';
import 'widgets/text.dart'; // Your CustomText widget
import 'globals.dart' as globals;

class CustomAppBar extends StatefulWidget {
  final String title;
  final Widget body;
  final bool subtitle;
  final bool add;

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
        color: CustomColors.offWhite,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 110.0,
              backgroundColor: CustomColors.primary,
              automaticallyImplyLeading: false,
              actions: widget.add
                  ? [
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                          const AddGoalPage(), // Replace with your AddGoal page
                        ),
                      );
                    },
                    child: Container(
                      width: 35.0,
                      height: 35.0,
                      decoration: BoxDecoration(
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
                SizedBox(width: 10),
              ]
                  : null,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  bool isCollapsed =
                      constraints.biggest.height <= kToolbarHeight + 50;

                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    centerTitle: isCollapsed,
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 0),
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
                              textHeight:
                              widget.subtitle ? 0.8 : null,
                            ),
                            if (widget.subtitle)
                              Padding(
                                padding:
                                const EdgeInsets.only(left: 2.0),
                                child: CustomText(
                                  text: globals.currentDate,
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
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 0, // Minimum height
                  maxHeight: double.infinity, // Prevent infinite height
                ),
                child: widget.body, // Ensure the body content is constrained
              ),
            ),
          ],
        ),
      ),
    );
  }
}
