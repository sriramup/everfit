import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/badge_widgets.dart';
import 'package:everfit/widgets/daily_quote.dart';
import 'package:everfit/widgets/daily_suggestions.dart';
import 'package:everfit/widgets/step_distance_summary.dart';
import 'package:everfit/widgets/text.dart';
import 'package:everfit/widgets/weather_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'journal.dart';
import 'widgets/tap_card.dart';
import 'widgets/calorie_summary.dart';
import 'health_data.dart';
import 'dart:async';

/// Displays the most vital information pertaining to other pages as well as motivational resources
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final HealthService _healthService = HealthService(); // To fetch health data
  bool? isHealthAuthorized; // Indicates if the app has access to health data
  int? totalSteps; // The total number of steps taken today
  int? activeCalories; // The calories burned today
  double? distanceWalked; // The distance walked or run today
  bool? incOrDecStep; // Tracks if today's steps increased compared to yesterday
  int? differenceStep; // Difference in steps between today and yesterday
  bool? incOrDecCal; // Tracks if today's calories burned increased or decreased
  int? differenceCal; // Difference in calories burned between today and yesterday
  bool? incOrDecDist; // Tracks if today's distance walked increased or decreased
  double? differenceDist; // Difference in distance walked between today and yesterday
  Timer? _timer; // A timer to periodically update data
  List<BadgeItem> recentBadges = []; // Badges the user recently earned

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start checking for updates periodically
    _initializeData(); // Load health data
    _fetchRecentBadges(); // Load recently earned badges
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when leaving the page
    super.dispose();
  }

  /// Starts a timer that updates health data and badges every 5 seconds
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _initializeData(); // Refresh health data
      _fetchRecentBadges(); // Refresh badges
    });
  }

  /// Loads recent badges the user has earned
  Future<void> _fetchRecentBadges() async {
    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // User ID for the database
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      List<BadgeItem> completed = [];

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
          isNew: data.containsKey('recent'),
        );

        if (progress >= amount) {
          completed.add(badge); // Add badge to the completed list if earned
        }
      }

      if (completed.length != recentBadges.length) {
        setState(() {
          recentBadges = completed; // Update the displayed badges
        });
      }
    } catch (e) {
      print('Error fetching badges: $e');
    }
  }

  /// Fetches the user's calorie data from yesterday for comparison
  Future<int> fetchPreviousCalories() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    final firestore = FirebaseFirestore.instance;

    try {
      final DocumentSnapshot userDoc =
      await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final prevSummary = data['prevSummary'] as Map<String, dynamic>;
        return prevSummary['calories'];
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    return 0;
  }

  /// Fetches the user's step count data from yesterday
  Future<int> fetchPreviousSteps() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    final firestore = FirebaseFirestore.instance;

    try {
      final DocumentSnapshot userDoc =
      await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final prevSummary = data['prevSummary'] as Map<String, dynamic>;
        return prevSummary['steps'];
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    return 0;
  }

  /// Fetches the user's distance data from yesterday
  Future<double> fetchPreviousDistance() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    final firestore = FirebaseFirestore.instance;

    try {
      final DocumentSnapshot userDoc =
      await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final prevSummary = data['prevSummary'] as Map<String, dynamic>;
        return prevSummary['distance'];
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    return 0;
  }

  /// Loads the user's health data and calculates differences from yesterday
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthorized = prefs.getBool('is_health_authorized') ?? false;

    // Stores live movement-related data from Apple Health
    if (isAuthorized) {
      final calories = await _healthService.fetchActiveCaloriesToday();
      final distance =
          (await _healthService.fetchDistanceToday())! * 0.000621371;
      final steps = await _healthService.fetchTotalStepsToday();

      // Compares Apple Health Data with yesterday's data stored in the database
      if (calories != activeCalories ||
          distance != distanceWalked ||
          steps != totalSteps) {
        final previousCalories = await fetchPreviousCalories();
        final calorieDifference = (calories ?? 0) - previousCalories;

        final previousSteps = await fetchPreviousSteps();
        final stepDifference = (steps ?? 0) - previousSteps;

        final previousDistance = await fetchPreviousDistance();
        final distanceDifference = (distance) - previousDistance;

        // Updates the UI display to show the most recent data
        setState(() {
          isHealthAuthorized = true;
          activeCalories = calories;
          distanceWalked = distance;
          totalSteps = steps;

          /* Stores the difference between today and yesterday summary which is represented
          with an up or down arrow depending on which day saw more progress in a category */
          incOrDecCal = calorieDifference > 0;
          differenceCal = calorieDifference.abs();

          incOrDecStep = stepDifference > 0;
          differenceStep = stepDifference.abs();

          incOrDecDist = distanceDifference > 0;
          differenceDist = distanceDifference.abs();
        });
      }
    } else {
      setState(() {
        isHealthAuthorized = false;
      });
    }
  }

  /// Requests access to Apple Health data
  Future<void> _requestHealthAuthorization() async {
    bool authorized = await _healthService.requestAuthorization();
    if (authorized) {
      // Links Apple Health across the entire app
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_health_authorized', true);

      setState(() {
        isHealthAuthorized = true;
      });

      await _initializeData();
    } else {
      print('Authorization denied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _checkHealthAuthorization(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: CustomColors.offWhite,
            ),
          );
        }

        final isHealthAuthorized = snapshot.data ?? false;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isHealthAuthorized)
                Column(
                  children: [
                    const SizedBox(height: 15),
                    /// Prompts the user to enable data sync
                    TapCard(
                      imagePath: 'assets/images/health.png',
                      text: 'Apple Health',
                      subText: 'Turn on sync',
                      border: CustomColors.primary,
                      onPressed: _requestHealthAuthorization,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              const SizedBox(height: 5),
              /// Display Summary Data
              if (isHealthAuthorized)
                Column(
                  children: [
                    // These fields are nullable, so default values given for safety
                    CalorieSummaryCard(
                      caloriesBurned: activeCalories ?? 0,
                      difference: differenceCal?.abs() ?? 0,
                      incOrDec: incOrDecCal,
                    ),
                    StepDistanceCard(
                      steps: totalSteps ?? 0,
                      stepDifference: differenceStep ?? 0,
                      distance: distanceWalked ?? 0,
                      distanceDifference: differenceDist ?? 0,
                      stepsIncOrDec: incOrDecStep,
                      distanceIncOrDec: incOrDecDist,
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              DailyQuote(
                dayOne: 'assets/images/daily_quote_1.png',
                dayTwo: 'assets/images/daily_quote_2.png',
              ),
              const SizedBox(height: 5),
              DailySuggestions(),
              const SizedBox(height: 5),
              // Reroutes user to Journal page separate from home
              TapCard(
                imagePath: 'assets/images/journal.png',
                imageColor: CustomColors.primary,
                text: 'Journal',
                subText: 'Log your experiences',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalPage(),
                    ),
                  );
                },
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: WeatherCard(),
              ),
              RecentBadgesWidget(badges: recentBadges),
            ],
          ),
        );
      },
    );
  }

  /// Safety check before reading Apple Health data
  Future<bool?> _checkHealthAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_health_authorized') ?? false;
  }

  @override
  bool get wantKeepAlive => true;
}

/// Creates a more simplified version of badges_page for quick view
class RecentBadgesWidget extends StatelessWidget {
  final List<BadgeItem> badges;

  const RecentBadgesWidget({
    super.key,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText(
                      text: 'Recent Badges',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.darkGray,
                      squash: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5.0),
            const Divider(
              thickness: 1.0,
              color: CustomColors.lightGray,
            ),
            const SizedBox(height: 10.0),
            /// Displays the 3 most recent badges
            Row(
              children: badges.take(3).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
