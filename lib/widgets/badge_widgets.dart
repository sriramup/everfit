import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // For sharing functionality
import 'dart:ui' as ui;

import '../colors.dart';

/// A container that groups badges by category and makes them clickable
class BadgeCategoryWidget extends StatelessWidget {
  final IconData? icon; // Icon to visually represent the category
  final String title; // Title of the category
  final VoidCallback onTap; // Action when the category is clicked
  final List<BadgeItem> badges; // List of badges in this category

  const BadgeCategoryWidget({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Opens a more detailed view of badges when clicked
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white, // Background color of the container
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Displays the icon and title at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null)
                      Row(
                        children: [
                          Icon(icon, color: CustomColors.darkGray, size: 24.0),
                          const SizedBox(width: 10.0),
                        ],
                      ),
                    CustomText(
                      text: title,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: CustomColors.darkGray,
                      squash: true,
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: CustomColors.gray, size: 18.0), // Arrow for navigating back
              ],
            ),
            const SizedBox(height: 3.0),
            const Divider(
              thickness: 1.0,
              color: CustomColors.offWhite,
            ),
            const SizedBox(height: 10.0),
            // Displays a few badges from the category
            Row(
              children: badges.take(4).toList(), // Shows up to 4 badges
            ),
          ],
        ),
      ),
    );
  }
}

/// A clickable badge item widget that reacts to user interactions
class BadgeItem extends StatefulWidget {
  final String imagePath; // Path to the badge image
  final String name; // Name of the badge
  final String message; // Description or message associated with the badge
  final bool isUnlocked; // Indicates if the badge has been earned
  final int progress; // Current progress towards earning the badge
  final int amount; // Target amount required to unlock the badge
  final bool? forRecent; // Optional flag for displaying recent badges
  final bool isNew; // Indicates if the badge is newly unlocked

  const BadgeItem({
    super.key,
    required this.imagePath,
    required this.name,
    required this.message,
    required this.isUnlocked,
    required this.progress,
    required this.amount,
    required this.isNew,
    this.forRecent,
  });

  @override
  _BadgeItemState createState() => _BadgeItemState();
}

class _BadgeItemState extends State<BadgeItem> {
  late bool isUnlocked; // Local state for badge unlock status
  late bool isNew; // Local state to track if the badge is new

  @override
  void initState() {
    super.initState();
    isUnlocked = widget.isUnlocked; // Initialize unlock status
    isNew = widget.isNew; // Initialize new status
  }

  /// After a recently earned badge is clicked, the new banner should disappear
  Future<void> _removeRecentField() async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ";
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('badges')
          .where('name', isEqualTo: widget.name)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'recent': FieldValue.delete(), // Remove the 'recent' field from the database
        });
      }

      // Update local state to remove "NEW" badge visually
      setState(() {
        isNew = false;
      });
    } catch (e) {
      print("Error removing 'recent' field: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Removes "NEW" status if applicable and navigates to badge details
        if (isNew) {
          _removeRecentField();
        }
        // Displays more badge-specific details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeViewPage(
              forRecent: widget.forRecent != null,
              badge: widget,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10.0),
        width: 60.0,
        height: 60.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.transparent,
          image: DecorationImage(
            colorFilter: ColorFilter.mode(
              isUnlocked ? CustomColors.primary : CustomColors.lightGray,
              BlendMode.srcATop, // Tints the image based on unlock status (gray for lock and green for unlocked)
            ),
            image: AssetImage(widget.imagePath),
            fit: BoxFit.cover,
          ),
        ),
        // Displays a "NEW" indicator if the badge is new
        child: isNew && widget.name == 'First Weight Drop'
            ? Stack(
          children: [
            Positioned(
              top: 2.0,
              right: 2.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: CustomColors.red,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const CustomText(
                  text: "NEW",
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  squash: true,
                ),
              ),
            ),
          ],
        )
            : null,
      ),
    );
  }
}

/// Displays the details of a single badge
class BadgeViewPage extends StatelessWidget {
  final BadgeItem badge; // The badge to display
  final bool forRecent; // Flag for recent badges

  const BadgeViewPage(
      {super.key, required this.badge, required this.forRecent});

  /// Captures the badge widget as an image and opens the share pop-up
  Future<void> _captureAndShareBadge(
      BuildContext context, GlobalKey key) async {
    try {
      final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image =
      await boundary?.toImage(pixelRatio: ui.PlatformDispatcher.instance.views.first.devicePixelRatio);
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        // Save the image temporarily for sharing
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/badge.png').create();
        await file.writeAsBytes(pngBytes);

        // Share the badge image using share_plus
        // Options include Messages, Instagram, and Snapchat
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this badge I unlocked!',
        );
      }
    } catch (e) {
      // Handle errors during sharing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share badge.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey shareKey =
    GlobalKey(); // Key to capture the widget for sharing

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
        title: CustomText(
          text: forRecent // Special case for the recent badges container in Home
              ? 'Recent Badge'
              : badge.isUnlocked
              ? 'Unlocked'
              : badge.progress == 0
              ? 'Locked'
              : 'In Progress', // Badge status as title
          fontSize: 25.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
          textHeight: 0.8,
        ),
        centerTitle: true,
        actions: badge.isUnlocked
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _captureAndShareBadge(context, shareKey),
            ),
          ),
        ]
            : null,
      ),
      body: Container(
        color: CustomColors.offWhite,
        child: Center(
          child: Padding(
            // Amount of information displayed varies depending on status
            padding: EdgeInsets.only(
              top: 100.0,
              // Resizes layout accordingly
              bottom: badge.progress > 0 && badge.progress < badge.amount
                  ? 160
                  : 200,
              left: 20.0,
              right: 20.0,
            ),
            child: RepaintBoundary(
              key: shareKey, // Widget to capture for sharing
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  children: [
                    // Display the image as a tint depending on unlocked (primary) or locked (gray)
                    Padding(
                      padding: const EdgeInsets.only(top: 50, left: 8.0),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10.0),
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.transparent,
                          image: DecorationImage(
                            colorFilter: ColorFilter.mode(
                              badge.isUnlocked
                                  ? CustomColors.primary
                                  : CustomColors.lightGray,
                              BlendMode.srcATop,
                            ),
                            image: AssetImage(badge.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomText(
                      text: badge.name,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: CustomColors.darkGray,
                      squash: true,
                    ),
                    const SizedBox(height: 10),
                    // Displays how badge was earned/how to unlock badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: CustomText(
                        textAlign: TextAlign.center,
                        text: badge.message,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.darkGray,
                        squash: true,
                        textHeight: 1.6,
                      ),
                    ),
                    // Displays progress if badge is in progress
                    if (badge.progress > 0 && badge.progress < badge.amount)
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          CustomText(
                            text: 'Progress: ${badge.progress}/${badge.amount}',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CustomColors.darkGray,
                            squash: true,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Bottom navigation for switching pages
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Default selection for badges page
        selectedItemColor: CustomColors.primary,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/home.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/goals.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/badges.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/discover.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/settings.png')),
            label: '',
          ),
        ],
        onTap: (index) {},
      ),
    );
  }
}

/// A page displaying a list of all badges within a specific status category (unlocked, in progress, locked)
class BadgeDetailPage extends StatelessWidget {
  final String title; // Title of the badge category
  final List<BadgeItem> badges; // List of badges in the category

  const BadgeDetailPage({super.key, required this.title, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: CustomText(
          text: title,
          fontSize: 25.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
          textHeight: 0.8,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: CustomColors.offWhite, // Background color for the page
        child: Padding(
          padding: EdgeInsets.only(
            top: 20.0,
            left: 20.0,
            right: 20.0,
            bottom: 630.0 - ((badges.length / 4).ceil()) * 80,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding:
              const EdgeInsets.only(top: 15.0, left: 20.0, right: 10.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // Number of badges per row
                  crossAxisSpacing: 25.0, // Spacing between badges
                  mainAxisSpacing: 25.0,
                  childAspectRatio: 1.19, // Maintains square badge display
                ),
                itemCount: badges.length, // Total badges to display
                itemBuilder: (context, index) {
                  return badges[index]; // Displays each badge as a widget
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Default selection for badges page
        selectedItemColor: CustomColors.primary,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/home.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/goals.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/badges.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/discover.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/settings.png')),
            label: '',
          ),
        ],
        onTap: (index) {},
      ),
    );
  }
}
