import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // For sharing functionality
import 'dart:ui' as ui;

import '../colors.dart';

// Widget for each badge category
class BadgeCategoryWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final List<BadgeItem> badges;

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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with icon and title
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
                    color: CustomColors.gray, size: 18.0),
              ],
            ),
            const SizedBox(height: 3.0),
            const Divider(
              thickness: 1.0,
              color: CustomColors.offWhite,
            ),
            const SizedBox(height: 10.0),
            Row(
              children: badges.take(4).toList(), // Show a maximum of 4 badges
            ),
          ],
        ),
      ),
    );
  }
}

// Badge Item Widget
class BadgeItem extends StatefulWidget {
  final String imagePath;
  final String name;
  final String message;
  final bool isUnlocked;
  final int progress;
  final int amount;
  final bool? forRecent;
  final bool isNew;

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
  late bool isUnlocked;
  late bool isNew;

  @override
  void initState() {
    super.initState();
    isUnlocked = widget.isUnlocked; // Initialize with the passed value
    isNew = widget.isNew; // Initialize with the passed value
  }

  Future<void> _removeRecentField() async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('badges')
          .where('name', isEqualTo: widget.name)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'recent': FieldValue.delete(),
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
        if (isNew) {
          _removeRecentField();
        }
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
              // Apply primary color
              BlendMode.srcATop, // Blend mode to tint the image
            ),
            image: AssetImage(widget.imagePath),
            fit: BoxFit.cover,
          ),
        ),
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

// Badge View Page
class BadgeViewPage extends StatelessWidget {
  final BadgeItem badge;
  final bool forRecent;

  const BadgeViewPage(
      {super.key, required this.badge, required this.forRecent});

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

        // Use share_plus to open the share sheet
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this badge I unlocked!',
        );
      }
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share badge.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey shareKey =
        GlobalKey(); // Key for capturing the widget as an image

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        title: CustomText(
          text: forRecent
              ? 'Recent Badge'
              : badge.isUnlocked
                  ? 'Unlocked'
                  : badge.progress == 0
                      ? 'Locked'
                      : 'In Progress',
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
            padding: EdgeInsets.only(
              top: 100.0,
              bottom: badge.progress > 0 && badge.progress < badge.amount
                  ? 160
                  : 200,
              left: 20.0,
              right: 20.0,
            ),
            child: RepaintBoundary(
              key: shareKey, // Attach the key to the widget to capture
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  children: [
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        // Dummy value, does not update
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
        onTap: (index) {
          // Dummy navigation, does nothing
        },
      ),
    );
  }
}

// Badge Detail Page
class BadgeDetailPage extends StatelessWidget {
  final String title;
  final List<BadgeItem> badges;

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
            Navigator.pop(context); // Navigate back
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
        color: CustomColors.offWhite,
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
                  crossAxisCount: 4,
                  // Adjust number of columns to avoid cutting images
                  crossAxisSpacing: 25.0,
                  // Adjust spacing between items
                  mainAxisSpacing: 25.0,
                  childAspectRatio:
                      1.19, // Ensure items maintain a square aspect ratio
                ),
                itemCount: badges.length, // Use dynamic length for badges
                itemBuilder: (context, index) {
                  return badges[index];
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        // Dummy value, does not update
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
        onTap: (index) {
          // Dummy navigation, does nothing
        },
      ),
    );
  }
}
