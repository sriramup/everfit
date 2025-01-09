import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/badge_widgets.dart';
import 'package:flutter/material.dart';
import '../colors.dart'; // Your custom colors
import '../widgets/text.dart'; // Your CustomText widget

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  Timer? _timer;

  // Current badge lists
  List<BadgeItem> unlocked = [];
  List<BadgeItem> inProgress = [];
  List<BadgeItem> locked = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchAndUpdateBadges(); // Initial fetch
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchAndUpdateBadges();
    });
  }

  Future<void> _fetchAndUpdateBadges() async {
    try {
      final badges = await _fetchBadges();

      // Compare and update state only if there's a change
      if (_isBadgeListChanged(badges['unlocked']!, unlocked) ||
          _isBadgeListChanged(badges['inProgress']!, inProgress) ||
          _isBadgeListChanged(badges['locked']!, locked)) {
        setState(() {
          unlocked = badges['unlocked']!;
          inProgress = badges['inProgress']!;
          locked = badges['locked']!;
        });
      }
    } catch (e) {
      print('Error fetching badges: $e');
    }
  }

  bool _isBadgeListChanged(List<BadgeItem> newList, List<BadgeItem> currentList) {
    if (newList.length != currentList.length) {
      return true;
    }

    for (int i = 0; i < newList.length; i++) {
      if (newList[i].message != currentList[i].message ||
          newList[i].progress != currentList[i].progress) {
        return true;
      }
    }
    return false;
  }

  Future<Map<String, List<BadgeItem>>> _fetchBadges() async {
    final unlocked = <BadgeItem>[];
    final inProgress = <BadgeItem>[];
    final locked = <BadgeItem>[];

    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final progress = data['progress'] ?? 0;
        final amount = data['amount'] ?? 1;
        final image = data['image'] ?? 'default.png';
        final name = data['name'] ?? 'Unnamed Badge';
        final message = data['message'] ?? '';

        final badge = BadgeItem(
          imagePath: 'assets/images/$image',
          name: name,
          message: message,
          isUnlocked: progress >= amount,
          progress: progress,
          amount: amount,
        );

        if (progress >= amount) {
          unlocked.add(badge);
        } else if (progress > 0) {
          inProgress.add(badge);
        } else {
          locked.add(badge);
        }
      }
    } catch (e) {
      print('Error fetching badges: $e');
    }

    return {
      'unlocked': unlocked,
      'inProgress': inProgress,
      'locked': locked,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unlocked Badges
          BadgeCategoryWidget(
            icon: Icons.lock_open,
            title: "Unlocked",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BadgeDetailPage(
                    title: "Unlocked",
                    badges: unlocked,
                  ),
                ),
              );
            },
            badges: unlocked,
          ),
          const SizedBox(height: 20.0),
          // In Progress Badges
          BadgeCategoryWidget(
            icon: Icons.timelapse,
            title: "In Progress",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BadgeDetailPage(
                    title: "In Progress",
                    badges: inProgress,
                  ),
                ),
              );
            },
            badges: inProgress,
          ),
          const SizedBox(height: 20.0),
          // Locked Badges
          BadgeCategoryWidget(
            icon: Icons.lock,
            title: "Locked",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BadgeDetailPage(
                    title: "Locked",
                    badges: locked,
                  ),
                ),
              );
            },
            badges: locked,
          ),
        ],
      ),
    );
  }
}
