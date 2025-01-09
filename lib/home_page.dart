import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/badge_widgets.dart';
import 'package:everfit/widgets/daily_quote.dart';
import 'package:everfit/widgets/daily_suggestions.dart';
import 'package:everfit/widgets/step_distance_summary.dart';
import 'package:everfit/widgets/text.dart';
import 'package:everfit/widgets/weather_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart'; // Your custom colors
import 'journal.dart';
import 'widgets/tap_card.dart'; // Import your TapCard widget
import 'widgets/calorie_summary.dart'; // Import your CalorieSummaryCard widget
import 'health_data.dart'; // Import your HealthService class
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final HealthService _healthService =
      HealthService(); // Initialize HealthService
  bool? isHealthAuthorized; // Flag to check health authorization
  int? totalSteps;
  int? activeCalories; // Active calories burned
  double? distanceWalked; // Distance walked or run
  bool? incOrDecStep; // For the arrow in the summary
  int? differenceStep; // Difference in steps for the arrow
  bool? incOrDecCal; // For the arrow in the summary
  int? differenceCal; // Difference in calories for the arrow
  bool? incOrDecDist; // For the arrow in the summary
  double? differenceDist; // Difference in distance for the arrow
  Timer? _timer;
  List<BadgeItem> recentBadges = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeData();
    _fetchRecentBadges(); // Fetch recent badges
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Check for updated health data every 5 seconds
      _initializeData();
      _fetchRecentBadges(); // Fetch recent badges
    });
  }

  Future<void> _fetchRecentBadges() async {
    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
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
        );

        if (progress >= amount) {
          completed.add(badge);
        }
      }
      if (completed.length != recentBadges.length) {
        setState(() {
          recentBadges = completed;
        });
      }
    } catch (e) {
      print('Error fetching badges: $e');
    }
  }

  Future<int> fetchPreviousCalories() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch the document for the specific user
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // Access prevSummary -> calories
        final data = userDoc.data() as Map<String, dynamic>;
        final prevSummary = data['prevSummary'] as Map<String, dynamic>;
        final previousCalories = prevSummary['calories'];

        return previousCalories;
        // Use the `previousCalories` variable as needed
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    return 0;
  }

  Future<int> fetchPreviousSteps() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch the document for the specific user
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // Access prevSummary -> calories
        final data = userDoc.data() as Map<String, dynamic>;
        final prevSummary = data['prevSummary'] as Map<String, dynamic>;
        final previousSteps = prevSummary['steps'];

        return previousSteps;
        // Use the `previousCalories` variable as needed
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    return 0;
  }

  Future<double> fetchPreviousDistance() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch the document for the specific user
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // Access prevSummary -> calories
        final data = userDoc.data() as Map<String, dynamic>;
        final prevSummary = data['prevSummary'] as Map<String, dynamic>;
        final previousDistance = prevSummary['distance'];

        return previousDistance;
        // Use the `previousCalories` variable as needed
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    return 0;
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthorized = prefs.getBool('is_health_authorized') ?? false;

    if (isAuthorized) {
      // Fetch active calories and distance
      final calories = await _healthService.fetchActiveCaloriesToday();
      final distance =
          (await _healthService.fetchDistanceToday())! * 0.000621371;
      final steps = await _healthService.fetchTotalStepsToday();

      if (calories != activeCalories ||
          distance != distanceWalked ||
          steps != totalSteps) {
        // Simulate a difference for the arrow (for demo purposes)
        final previousCalories = await fetchPreviousCalories();
        final calorieDifference = (calories ?? 0) - previousCalories;

        final previousSteps = await fetchPreviousSteps();
        final stepDifference = (steps ?? 0) - previousSteps;

        final previousDistance = await fetchPreviousDistance();
        final distanceDifference = (distance) - previousDistance;

        setState(() {
          isHealthAuthorized = true;
          activeCalories = calories;
          distanceWalked = distance;
          totalSteps = steps;
          if (calorieDifference > 0) {
            incOrDecCal = true;
          }
          if (calorieDifference < 0) {
            incOrDecCal = false;
          }
          differenceCal = calorieDifference.abs();
          if (stepDifference > 0) {
            incOrDecStep = true;
          }
          if (stepDifference < 0) {
            incOrDecStep = false;
          }
          differenceStep = stepDifference.abs();
          if (distanceDifference > 0) {
            incOrDecDist = true;
          }
          if (distanceDifference < 0) {
            incOrDecDist = false;
          }
          differenceDist = distanceDifference.abs();
        });
      }
    } else {
      setState(() {
        isHealthAuthorized = false;
      });
    }
  }

  Future<void> _requestHealthAuthorization() async {
    bool authorized = await _healthService.requestAuthorization();
    if (authorized) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_health_authorized', true);

      setState(() {
        isHealthAuthorized =
            true; // Update the UI to reflect the authorization status
      });

      // Fetch initial health data
      await _initializeData();
    } else {
      print('Authorization denied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _checkHealthAuthorization(),
      // Check health authorization before building
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: CustomColors.offWhite,
            ),
          ); // Show loading spinner
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
              if (isHealthAuthorized)
                Column(
                  children: [
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
                }, backgroundColor: Colors.white,
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

  Future<bool?> _checkHealthAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_health_authorized') ?? false;
  }

  @override
  bool get wantKeepAlive => true;
}

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
            // Header Row with icon and title
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
            Row(
              children: badges.take(3).toList(), // Show a maximum of 4 badges
            ),
          ],
        ),
      ),
    );
  }
}
