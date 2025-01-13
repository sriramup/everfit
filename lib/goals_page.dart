import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_meal.dart';
import 'widgets/button.dart';
import 'widgets/mini_info.dart';
import 'widgets/slider_card.dart';
import 'widgets/tap_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../colors.dart';
import '../widgets/text.dart';
import 'health_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

import 'notifications.dart';



/// The main page for managing and displaying a list of user goals.
///
/// This page is responsible for fetching the user's goals from Firestore,
/// updating goal progress, checking goal completion status, and maintaining
/// a periodic update mechanism to keep goal data in sync.
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  /// A timer that periodically updates the goal data.
  Timer? _timer;

  /// A service to fetch health-related data (e.g., steps, calories).
  final HealthService _healthService = HealthService();

  /// The current list of user goals displayed on the page.
  List<GoalProgress> goals = [];

  /// Initializes the state by starting the timer and fetching goals.
  @override
  void initState() {
    super.initState();
    _startTimer(); // Begins periodic goal updates
    _fetchAndUpdateGoals(); // Fetch goals for the first time
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchAndUpdateGoals();
    });
  }

  /// Checks if a goal has been completed (its progress matches or exceeds its target)
  Future<void> _checkCompletion(GoalProgress goal) async {
    final String userId = "B7FOLVzsJ0trs9DLvYcZ";
    final goalId = goal.documentID;
    final firestore = FirebaseFirestore.instance;

    final DocumentSnapshot userDoc = await firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final progress = data['progress'];
      final details = data['details'] as Map<String, dynamic>;
      final target = details['target'];
      final type = details['type'];
      final complete = data['complete'];

      /* Depending on whether the goal is trying to be met or avoided,
      completion criteria changes. */
      bool isComplete;
      if (type == 'avoid') {
        isComplete = progress < target;
      } else if (type == 'reach') {
        isComplete = progress >= target;
      } else {
        return; // Skip if type is invalid or undefined
      }

      /// If the goal is incomplete in the database but complete now.
      if (!complete && isComplete) {
        final userDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc(goalId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final currentStreak = data['streak'] ?? 0;

          /// Mark as complete and increment the streak.
          await firestore
              .collection('users')
              .doc(userId)
              .collection('goals')
              .doc(goalId)
              .update({'complete': true, 'streak': currentStreak + 1});
        }
        /// If the goal is complete in the database but incomplete now.
      } else if (complete && !isComplete) {
        final userDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc(goalId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final currentStreak = data['streak'] ?? 0;

          // Mark as incomplete and decrement streak
          await firestore
              .collection('users')
              .doc(userId)
              .collection('goals')
              .doc(goalId)
              .update({'complete': false, 'streak': currentStreak - 1});
        }
      }
    }
  }

  /// Updates progress for goals that are tracked intuitively
  /// For movement-related goals, this means using Apple Health
  Future<void> _updateIntuitive(GoalProgress goal) async {
    if (goal.category == 'active') {
      try {
        // Fetch relevant health data based on the goal name
        String goalName = goal.details['name'];
        dynamic fetchedData;

        if (goalName.toLowerCase().contains('steps')) {
          fetchedData = await _healthService.fetchTotalStepsToday();
        } else if (goalName.toLowerCase().contains('calories')) {
          fetchedData = await _healthService.fetchActiveCaloriesToday();
        } else if (goalName.toLowerCase().contains('travel')) {
          fetchedData = (await _healthService.fetchDistanceToday())! *
              0.000621371; // Convert to miles
        } else {
          print('No matching health data logic for goal: $goalName');
          return;
        }

        final String userId =
            "B7FOLVzsJ0trs9DLvYcZ";
        final goalId = goal.documentID;
        final firestore = FirebaseFirestore.instance;

        // Update goal progress in Firestore
        final DocumentSnapshot userDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc(goalId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final previousData = data['progress'];

          if (fetchedData != previousData) {
            await firestore
                .collection('users')
                .doc(userId)
                .collection('goals')
                .doc(goalId)
                .update(
                {'progress': previousData + (fetchedData - previousData)});

            // Update badges if their name contains any word from the goal's name
            final goalNameWords = data['details']['name']
                .toString()
                .toLowerCase()
                .split(' ')
                .where((word) => word.isNotEmpty)
                .toList();

            final badgesSnapshot = await firestore
                .collection('users')
                .doc(userId)
                .collection('badges')
                .get();

            for (var badgeDoc in badgesSnapshot.docs) {
              final badgeData = badgeDoc.data();
              final badgeName = badgeData['name'].toString().toLowerCase();

              // Check if any word in the goal name is present in the badge name
              if (goalNameWords.any((word) => badgeName.contains(word))) {
                final badgeProgress = badgeData['progress'] ?? 0;
                await badgeDoc.reference.update({
                  'progress': badgeProgress + (fetchedData - previousData),
                });
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching goal-specific data: $e');
      }
    }
  }

  /// Fetches goals from Firestore, checks for completion, and updates progress intuitively.
  Future<void> _fetchAndUpdateGoals() async {
    try {
      final fetchedGoals = await _fetchGoals();
      // Iterate through each goal to perform updates
      for (GoalProgress g in fetchedGoals) {
        if (g.details['intuitiveUpdate'] != null) {
          if (g.details['intuitiveUpdate']) {
            _updateIntuitive(g);
          }
        }
        _checkCompletion(g);
      }

      // Update the UI if the goal list has changed
      if (_isGoalListChanged(fetchedGoals, goals)) {
        setState(() {
          goals = fetchedGoals;
        });
      }
    } catch (e) {
      print('Error fetching goals: $e');
    }
  }

  /// Compares two lists of goals to check if there are any changes.
  bool _isGoalListChanged(
      List<GoalProgress> newList, List<GoalProgress> currentList) {
    if (newList.length != currentList.length) {
      return true;
    }

    for (int i = 0; i < newList.length; i++) {
      if (newList[i].progress != currentList[i].progress ||
          newList[i].details['reminders'] !=
              currentList[i].details['reminders'] ||
          newList[i].details['intuitiveUpdate'] !=
              currentList[i].details['intuitiveUpdate'] ||
          newList[i].complete != currentList[i].complete) {
        return true;
      }
    }
    return false;
  }

  /// Fetches the list of goals from Firestore.
  Future<List<GoalProgress>> _fetchGoals() async {
    final List<GoalProgress> fetchedGoals = [];

    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        fetchedGoals.add(GoalProgress(
          analysis: data['analysis'] ?? {},
          category: data['category'] ?? '',
          complete: data['complete'] ?? false,
          details: data['details'] ?? {},
          progress: data['progress'] ?? 0,
          target: data['details']['target'] ?? 0,
          name: data['details']['name'] ?? '',
          units: data['details']['units'] ?? '',
          streak: data['streak'] ?? 0,
          documentID: doc.id,
          onDelete: () {
            setState(() {
              goals.removeWhere((goal) => goal.documentID == doc.id);
            });
          },
        ));
      }
    } catch (e) {
      print('Error fetching goals: $e');
    }

    return fetchedGoals;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      // Displays each goal the user has active in a vertical column
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...goals.map((goal) => goal),
        const MiniInfo(text: 'Tap and hold to remove a goal'),
      ]),
    );
  }
}

/// Displays information about a specific goal, and provides functionality for interacting with the goal,
/// Such as opening up a more detailed popup to edit and analyze.
class GoalProgress extends StatelessWidget {
  /// Analysis data for the goal, which may include trends or statistics.
  final Map<String, dynamic>? analysis;

  /// The category of the goal (e.g., "active", "nutrition", "weight").
  final String category;

  final String name;

  /// The unit of measurement for the goal's progress (e.g., "steps", "calories").
  final String units;

  final bool complete;

  /// Detailed metadata about the goal (e.g., target, period, reminders).
  final Map<String, dynamic> details;

  /// The current progress towards achieving the goal.
  final int progress;

  /// The target value required to complete the goal.
  final int target;

  final int streak;

  /// The Firestore document ID for this goal.
  final String documentID;

  /// A callback function that is triggered when the goal is deleted.
  final VoidCallback onDelete;

  /// Creates an instance of the `GoalProgress` widget.
  const GoalProgress({
    super.key,
    this.analysis,
    required this.name,
    required this.units,
    required this.category,
    required this.complete,
    required this.details,
    required this.progress,
    required this.target,
    required this.streak,
    required this.documentID,
    required this.onDelete,
  });

  /// Deletes the goal from Firestore and triggers the `onDelete` callback.
  ///
  /// If an error occurs during deletion, a snack bar is shown with an error message.
  Future<void> _deleteGoal(BuildContext context) async {
    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(documentID)
          .delete();

      onDelete(); // Refreshes the page to no longer show the goal
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting goal')),
      );
    }
  }

  /// Displays a confirmation dialog for deleting the goal.
  ///
  /// If the user confirms, the goal is deleted using `_deleteGoal`.
  void _showDeleteGoalPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: 'Are you sure?',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CustomColors.darkGray,
                  squash: true,
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context); // Close the popup
                    await _deleteGoal(context); // Execute the delete logic
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: CustomColors.red,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'Delete',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        squash: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the widget tree for the goal's UI representation.
  ///
  /// The widget includes:
  /// - An icon representing the category of the goal.
  /// - The goal's name, progress, and streak.
  /// - A progress bar indicating the percentage completion of the goal.
  /// - A "COMPLETE" badge if the goal is finished.
  @override
  Widget build(BuildContext context) {
    final progressPercentage = (progress / target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        // Navigates to the detailed page of the goal when tapped.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoalDetailPage(
              goal: GoalProgress(
                name: name,
                units: units,
                category: category,
                complete: complete,
                details: details,
                progress: progress,
                target: target,
                documentID: documentID,
                onDelete: onDelete,
                streak: streak,
              ),
            ),
          ),
        );
      },
      onLongPress: () async {
        // Opens the delete confirmation popup when long-pressed.
        _showDeleteGoalPopup(context);
      },
      child: Column(
        children: [
          if (complete) const SizedBox(height: 15.0),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 15.0),
                padding: const EdgeInsets.only(top: 15.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 15.0, right: 15),
                      child: Row(
                        children: [
                          // Icon based on the goal's category
                          CircleAvatar(
                            radius: 20.0,
                            backgroundColor: CustomColors.primaryFaded,
                            child: Icon(
                              category == 'active'
                                  ? Icons.local_fire_department
                                  : category == 'nutrition'
                                  ? Icons.no_food_rounded
                                  : category == 'weight'
                                  ? Icons.monitor_weight
                                  : category == 'drink'
                                  ? Icons.local_drink
                                  : category == 'custom'
                                  ? Icons.folder_special
                                  : Icons.mode_night,
                              color: CustomColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          // Goal name
                          CustomText(
                            text: details['name'] ?? 'Unnamed Goal',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: CustomColors.darkGray,
                            squash: true,
                          ),
                          const SizedBox(width: 10.0),
                          // Streak display
                          streak > 0
                              ? Expanded(
                            child: CustomText(
                              text: "🔥 $streak",
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                              squash: true,
                            ),
                          )
                              : Expanded(child: Container()),
                          // Progress display
                          Container(
                            decoration: BoxDecoration(
                              color: CustomColors.primaryFaded,
                              borderRadius: BorderRadius.circular(13.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0, vertical: 9.0),
                              child: CustomText(
                                text: "$progress/$target",
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: CustomColors.primary,
                                squash: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13.0),
                    // Progress bar
                    LinearPercentIndicator(
                      lineHeight: 3.0,
                      percent: progressPercentage,
                      progressColor: CustomColors.primary,
                      backgroundColor: CustomColors.primaryFaded,
                      barRadius: const Radius.circular(5.0),
                    ),
                  ],
                ),
              ),
              // "COMPLETE" badge if the goal is finished
              if (complete)
                Positioned(
                  top: -15,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 110.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CustomColors.red,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      alignment: Alignment.center,
                      child: CustomText(
                        text: "COMPLETE!",
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        squash: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Displays the detailed view of a goal and provides functionalities
/// for editing progress, viewing analysis, and managing goal settings.
class GoalDetailPage extends StatefulWidget {
  final GoalProgress goal;

  const GoalDetailPage({super.key, required this.goal});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late int progress; // Tracks the current progress of the goal.
  final TextEditingController _progressController = TextEditingController(); // Controller for progress input.
  final FocusNode _progressFocusNode = FocusNode(); // Focus node to detect when input loses focus.
  final PageController _pageController = PageController(initialPage: 0); // Controls the tab navigation.
  int _currentIndex = 0; // Tracks the current tab index.
  String _selectedTimeframe = 'Daily'; // Selected timeframe for analysis (Daily/Weekly/Monthly).
  Map<String, dynamic> analysisData = {}; // Stores analysis data retrieved from Firestore.

  @override
  void initState() {
    super.initState();
    progress = widget.goal.progress;
    _progressController.text = progress.toString(); // Initialize the controller

    // Add a listener to handle when keyboard is active
    _progressFocusNode.addListener(() {
      if (!_progressFocusNode.hasFocus) {
        // If the TextField loses focus, call updateProgress
        final int? newProgress = int.tryParse(_progressController.text);
        if (newProgress != null && newProgress >= 0 && newProgress != progress) {
          _updateProgress(newProgress);
        } else {
          _progressController.text = progress.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose(); // Dispose the controller
    _progressFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  /// Updates the goal's progress in Firestore and reflects changes in the UI.
  void _updateProgress(int newProgress) async {
    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ";
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Update the goal's progress in Firestore
      await firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(widget.goal.documentID)
          .update({'progress': newProgress});

      // Adjust biometrics if the goal affects the user's weight
      if (widget.goal.details['name'].toString().toLowerCase().contains('weight gain')) {
        await firestore.collection('users').doc(userId).update({
          'biometrics.weight': FieldValue.increment(newProgress - progress),
        });
      } else if (widget.goal.details['name'].toString().toLowerCase().contains('weight loss')) {
        await firestore.collection('users').doc(userId).update({
          'biometrics.weight': FieldValue.increment(progress - newProgress),
        });
      }

      // Update badge progress if its category matches with the goal's category
      final goalNameWords = widget.goal.details['name']
          .toString()
          .toLowerCase()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList();

      final badgesSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      for (var badgeDoc in badgesSnapshot.docs) {
        final badgeData = badgeDoc.data();
        final badgeName = badgeData['name'].toString().toLowerCase();

        // Check if any word in the goal name is present in the badge name
        if (goalNameWords.any((word) => badgeName.contains(word))) {
          final badgeProgress = badgeData['progress'] ?? 0;
          await badgeDoc.reference.update({
            'progress': badgeProgress + (newProgress - progress),
          });
        }
      }

      // Update the local progress state
      setState(() {
        progress = newProgress;
        _progressController.text = newProgress.toString();
      });
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  /// Switches between tabs in the PageView and fetches relevant analysis data.
  void _onTabTapped(int index) {
    _fetchAnalysisData();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Updates the reminder setting for the goal in Firestore.
  /// Allows the user to recieve push notifications for the goal
  void _updateReminders(bool reminders) async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ";
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(widget.goal.documentID)
          .update({'details.reminders': reminders});
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  /// Updates whether the goal gets updates manually or intuitively in Firestore.
  void _updateIntuitive(bool intuitiveUpdate) async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ";
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(widget.goal.documentID)
          .update({'details.intuitiveUpdate': intuitiveUpdate});
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  /// Fetches analysis data for the goal from Firestore.
  Future<void> _fetchAnalysisData() async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(widget.goal.documentID)
          .get();

      if (doc.exists) {
        setState(() {
          analysisData = doc['analysis'] ?? {};
        });
      }
    } catch (e) {
      print('Error fetching analysis data: $e');
    }
  }

  /// Builds a bar chart displaying goal completion progress.
  /// Groups progress by days, weeks, and months
  Widget _buildBarChart() {
    // Determine the key for analysis data based on the selected timeframe.
    final String dbKey = _selectedTimeframe.toLowerCase() == 'daily'
        ? 'days'
        : _selectedTimeframe.toLowerCase() == 'weekly'
            ? 'weeks'
            : 'months';

    // Set the max value and interval dynamically based on the selected timeframe
    final double maxY = _selectedTimeframe == 'Daily'
        ? 600
        : _selectedTimeframe == 'Weekly'
            ? 2800
            : 6800;
    final double interval = _selectedTimeframe == 'Daily'
        ? 150
        : _selectedTimeframe == 'Weekly'
            ? 700
            : 1700;

    // Retrieve data from Firebase
    final List<dynamic> data = analysisData[dbKey] ?? [];

    // Container for the bar chart
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(
            show: false, // No border around the chart
          ),
          gridData: FlGridData(show: false),
          // Hide grid lines
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval, // Dynamically set interval
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 11, color: CustomColors.black),
                  );
                },
              ),
            ),
            // x-value represents time frame
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (_selectedTimeframe == 'Daily') {
                    const days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        days[value.toInt() % 7],
                        style: const TextStyle(
                            fontSize: 11, color: CustomColors.black),
                      ),
                    );
                  } else if (_selectedTimeframe == 'Weekly') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'W${value.toInt() + 1}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    );
                  } else {
                    const months = [
                      'J',
                      'F',
                      'M',
                      'A',
                      'MY',
                      'JN',
                      'JY',
                      'AU',
                      'S',
                      'O',
                      'N',
                      'D'
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        months[value.toInt() % 12],
                        style:
                            const TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    );
                  }
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Hide top titles
            rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)), // Hide right titles
          ),
          groupsSpace: 10,
          // Create rods representing data and animate them
          barGroups: data
              .asMap()
              .entries
              .map(
                (entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: CustomColors.primary,
                      width: 12,
                      borderRadius:
                          BorderRadius.circular(10), // Rounded bar ends
                    ),
                  ],
                ),
              )
              .toList(),
          maxY: maxY, // Dynamically set the maximum y value
        ),
        duration: const Duration(milliseconds: 800),
        // Set animation duration here
        curve: Curves.easeInOut, // Customize the curve
      ),
    );
  }

  /// Builds a card displaying various statistics such as all time completions and best streak.
  Widget _buildStatsCard(String label, String value, String? unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: value,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: CustomColors.primary,
                  squash: true,
                ),
                if (unit != null)
                  Row(
                    children: [
                      SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: CustomText(
                          text: unit,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CustomColors.gray,
                          squash: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            CustomText(
              text: label,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CustomColors.darkGray,
              squash: true,
              textHeight: 1,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Allows user to update goal progress as well as reminders and intuive updates.
  Widget _buildEditPage() {
    // Calculate the progress percentage for the CircularPercentIndicator.
    final progressPercentage = (progress / widget.goal.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
      child: Column(
        children: [
          // Progress container displaying the CircularPercentIndicator and controls.
          Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "Progress",
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: CustomColors.darkGray,
                  squash: true,
                ),
                SizedBox(height: 3.0),
                const Divider(
                  thickness: 1.0,
                  color: CustomColors.lightGray,
                ),
                SizedBox(height: 15),
                Center(
                  // CircularPercentIndicator with controls for increasing/decreasing progress.
                child: CircularPercentIndicator(
                    radius: 130.0,
                    lineWidth: 20.0,
                    percent: progressPercentage,
                    center: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decrement progress button.
                        IconButton(
                          icon: const Icon(Icons.remove_circle, size: 35),
                          color: CustomColors.primary,
                          onPressed: () {
                            if (progress > 0) {
                              _updateProgress(progress - 1);
                            }
                          },
                        ),
                        const SizedBox(width: 3),
                        // Progress input field and target display.
                        Padding(
                          padding: const EdgeInsets.only(top: 100.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 110,
                                // Makes the TextField take full width of the parent
                                decoration: BoxDecoration(
                                  color: CustomColors.primaryFaded,
                                  borderRadius: BorderRadius.circular(13.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 30.0),
                                  child: TextField(
                                    cursorColor: CustomColors.primary,
                                    focusNode: _progressFocusNode,
                                    // Assign FocusNode
                                    controller: _progressController,
                                    // Set the controller
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      // Only allow digits
                                    ],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w700,
                                      color: CustomColors.primary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                    // Update progress only if it has changed
                                    onSubmitted: (value) async {
                                      final int? newProgress =
                                          int.tryParse(value);
                                      if (newProgress != null &&
                                          newProgress >= 0 && newProgress != progress) {
                                        _updateProgress(
                                            newProgress);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Invalid progress value. Please enter a valid number.',
                                            ),
                                          ),
                                        );
                                        _progressController.text = progress
                                            .toString(); // Reset to the last valid value
                                      }
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.0),
                              CustomText(
                                text: "/${widget.goal.target}",
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                color: CustomColors.gray,
                                squash: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 3),
                        // Increment progress button.
                        IconButton(
                          icon: const Icon(Icons.add_circle, size: 35),
                          color: CustomColors.primary,
                          onPressed: () {
                            if (progress < widget.goal.target) {
                              _updateProgress(progress + 1);
                            }
                          },
                        ),
                      ],
                    ),
                    progressColor: CustomColors.primary,
                    backgroundColor: CustomColors.primaryFaded,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ),
                const SizedBox(height: 5.0),
              ],
            ),
          ),
          const SizedBox(height: 15.0),
          // Reminder slider to toggle daily notifications.
          SliderCard(
            text: 'Reminders',
            onActivate: () async {
              _updateReminders(true);
              widget.goal.details['reminders'] = true;

              final notificationService = NotificationService();
              await notificationService.requestPermission();
              await notificationService.scheduleDailyNotification(
                id: 1,
                title: "Goal Reminder",
                body: "Only ${widget.goal.target - progress} ${widget.goal.units}s left to complete your ${widget.goal.name} goal!",
              );
            },
            onDeactivate: () {
              _updateReminders(false);
              widget.goal.details['reminders'] = false;
            },
            isActive: widget.goal.details['reminders'],
          ),
          const SizedBox(height: 15.0),
          // Intuitive update slider and scan meal button for nutrition goals.
          if (widget.goal.details['intuitiveUpdate'] != null)
            Column(
              children: [
                SliderCard(
                  text: 'Intuitive Update',
                  onActivate: () {
                    setState(() {
                      _updateIntuitive(true);
                      widget.goal.details['intuitiveUpdate'] = true;
                    });
                  },
                  onDeactivate: () {
                    setState(() {
                      _updateIntuitive(false);
                      widget.goal.details['intuitiveUpdate'] = false;
                    });
                  },
                  isActive: widget.goal.details['intuitiveUpdate'],
                ),
                // Allows user to take a picture of their meal and updates goals with macronutrient data
                const SizedBox(height: 15.0),
                if (widget.goal.category == 'nutrition' && widget.goal.details['intuitiveUpdate'])
                  CustomButton(
                    text: 'Scan Meal',
                    textSize: 18,
                    onPressed: () async {
                      final cameraStatus = await Permission.camera.status;
                      final microphoneStatus = await Permission.microphone.status;

                      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
                        // Navigate to ScanMealPage if permission is already granted
                        List<CameraDescription> cameras = await availableCameras();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanMealPage(goal: widget.goal, cameras: cameras,),
                          ),
                        );
                      } else {
                        // Request permission again or direct the user to app settings
                        final newCameraStatus = await Permission.camera.request();
                        final newMicrophoneStatus = await Permission.camera.request();

                        if (newCameraStatus.isGranted && newMicrophoneStatus.isGranted) {
                          // Permission granted, navigate to ScanMealPage
                          List<CameraDescription> cameras = await availableCameras();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScanMealPage(goal: widget.goal, cameras: cameras,),
                            ),
                          );
                        } else {
                          print("access not granted");
                        }
                      }
                    },
                    backgroundColor: CustomColors.primary,
                    textColor: Colors.white,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Builds the Analysis Page UI for displaying goal progress trends and statistics.
  Widget _buildAnalysisPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container displaying trends and a bar chart.
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row for the "Trends" title and timeframe selector.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title for the trends section.
                    CustomText(
                      text: "Trends",
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CustomColors.darkGray,
                      squash: true,
                    ),
                    // Timeframe selector (Daily, Weekly, Monthly).
                    Container(
                      decoration: BoxDecoration(
                        color: CustomColors.offWhite,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: ['Daily', 'Weekly', 'Monthly'].map((timeframe) {
                          final bool isSelected =
                              _selectedTimeframe == timeframe; // Check if the timeframe is selected.
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedTimeframe = timeframe; // Update the selected timeframe.
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CustomColors.primary // Highlight the selected timeframe.
                                    : CustomColors.offWhite,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: CustomText(
                                text: timeframe,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white // Highlight text for selected.
                                    : CustomColors.primary,
                                squash: true,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bar chart for visualizing trends.
                _buildBarChart(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Row displaying total completions and best streak.
          Row(
            children: [
              _buildStatsCard('Total Completions',
                  '${analysisData['completions'] ?? 0}', null),
              const SizedBox(width: 10),
              _buildStatsCard(
                  'Best Streak', '${analysisData['bestStreak'] ?? 0}', 'Days'),
            ],
          ),
          const SizedBox(height: 10),
          // Row displaying daily average and all-time progress.
          Row(
            children: [
              _buildStatsCard(
                  'Daily Average', '${analysisData['average'] ?? 0}', 'Cal'),
              const SizedBox(width: 10),
              _buildStatsCard(
                  'All Time', '${analysisData['allTime'] ?? 0}', 'Cal'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds the main UI structure of the Goal Detail page.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hides the keyboard when tapping outside
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevents UI resizing when the keyboard appears
        appBar: AppBar(
          backgroundColor: CustomColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Navigates back to the previous screen
            },
          ),
          title: CustomText(
            text: widget.goal.details['name'] ?? 'Goal Detail', // Displays the goal name
            fontSize: 25.0,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            squash: true,
          ),
          centerTitle: true, // Centers the title
        ),
        body: Container(
          color: CustomColors.offWhite, // Sets the background color
          child: Column(
            children: [
              // Custom tab selector
              Padding(
                padding: const EdgeInsets.only(
                    left: 70.0, right: 70.0, top: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      // Edit tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabTapped(0), // Switches to the Edit tab
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            decoration: BoxDecoration(
                              color: _currentIndex == 0
                                  ? CustomColors.primary // Highlights selected tab
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(13.0),
                            ),
                            child: CustomText(
                              text: "Edit",
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: _currentIndex == 0
                                  ? Colors.white // Highlights text in selected tab
                                  : CustomColors.darkGray,
                              squash: true,
                            ),
                          ),
                        ),
                      ),
                      // Analysis tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabTapped(1), // Switches to the Analysis tab
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            decoration: BoxDecoration(
                              color: _currentIndex == 1
                                  ? CustomColors.primary // Highlights selected tab
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(13.0),
                            ),
                            child: CustomText(
                              text: "Analysis",
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: _currentIndex == 1
                                  ? Colors.white // Highlights text in selected tab
                                  : CustomColors.darkGray,
                              squash: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // PageView for switching between Edit and Analysis pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index; // Updates the current tab index
                    });
                  },
                  children: [
                    // Edit page
                    SingleChildScrollView(
                      child: _buildEditPage(),
                    ),
                    // Analysis page
                    if (analysisData != {}) // Only displays if analysisData exists
                      SingleChildScrollView(
                        child: _buildAnalysisPage(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom Navigation Bar
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1, // Highlights the "Goals" tab
          selectedItemColor: CustomColors.primary,
          backgroundColor: Colors.white,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            // Home tab
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/home.png')),
              label: '',
            ),
            // Goals tab
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/goals.png')),
              label: '',
            ),
            // Badges tab
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/badges.png')),
              label: '',
            ),
            // Discover tab
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/discover.png')),
              label: '',
            ),
            // Settings tab
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/settings.png')),
              label: '',
            ),
          ],
          onTap: (index) {
            // Navigation logic can be added here
          },
        ),
      ),
    );
  }
}

/// Allows the user to add a new goal by selecting from predefined categories or creating a custom goal.
class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  int _selectedIndex = 0; // Index of the currently selected goal category

  // Separate lists for titles and asset paths
  final List<String> _goalTitles = [
    'Active',
    'Wellness',
    'Nutrition',
    'Custom'
  ];
  final List<String> _goalIcons = [
    'assets/images/active.png',
    'assets/images/wellness.png',
    'assets/images/nutrition.png',
    'assets/images/custom.png',
  ];

  // List of goal options and corresponding icon asset paths.
  List<Widget> _buildTapCardsByCategory(String category) {
    if (category == 'Active') {
      return [
        TapCard(
          text: 'Calories Burned',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Calories Burned',
                  category: 'active',
                  unit: 'Cal',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'active',
        ),
        TapCard(
          text: 'Steps',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Steps',
                  category: 'active',
                  unit: 'Steps',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'active',
        ),
        TapCard(
          text: 'Distance',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Distance',
                  category: 'active',
                  unit: 'Mi',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'active',
        ),
      ];
    } else if (category == 'Wellness') {
      return [
        TapCard(
          text: 'Weight Gain',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Weight Gain',
                  category: 'weight',
                  unit: 'Lb(s)',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'weight',
        ),
        TapCard(
          text: 'Weight Loss',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Weight Loss',
                  category: 'weight',
                  unit: 'Lb(s)',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'weight',
        ),
        TapCard(
          text: 'Sleep Duration',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Sleep Duration',
                  category: 'sleep',
                  unit: 'Hours',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'sleep',
        ),
        TapCard(
          text: 'Drink Water',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Drink Water',
                  category: 'drink',
                  unit: 'Liters',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'drink',
        ),
      ];
    } else if (category == 'Nutrition') {
      return [
        TapCard(
          text: 'Calorie Intake',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Calorie Intake',
                  category: 'nutrition',
                  unit: 'Cal',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'nutrition',
        ),
        TapCard(
          text: 'Protein Intake',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Protein Intake',
                  category: 'nutrition',
                  unit: 'g',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'nutrition',
        ),
        TapCard(
          text: 'Carbohydrate Intake',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Carbohydrate Intake',
                  category: 'nutrition',
                  unit: 'g',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'nutrition',
        ),
        TapCard(
          text: 'Fat Intake',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Fat Intake',
                  category: 'nutrition',
                  unit: 'g',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'nutrition',
        ),
        TapCard(
          text: 'Meal Count',
          imagePath: '',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalCustomizationPage(
                  isCustom: false,
                  name: 'Meal Count',
                  category: 'nutrition',
                  unit: 'Count',
                ),
              ),
            );
          },
          backgroundColor: Colors.white,
          containerColor: CustomColors.primaryFaded,
          category: 'nutrition',
        ),
      ];
      /// If the category is custom, all fields including title are set by the user
    } else if (category == 'Custom') {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: CustomButton(
            text: 'New',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalCustomizationPage(
                    isCustom: true,
                    name: '',
                    category: 'custom',
                  ),
                ),
              );
            },
            backgroundColor: CustomColors.primary,
            textColor: Colors.white,
            textSize: 18.0,
          ),
        ),
      ];
    }
    return []; // Default empty list for invalid categories
  }

  /// Format the goal options in a vertical column view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(148),
        // Increase height of the AppBar
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }, // Custom back button behavior
            color: Colors.white,
          ),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CustomText(
                text: 'Add Goal',
                fontSize: 25.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                squash: true,
                textHeight: 0.8,
              ),
              const SizedBox(height: 10),
            ],
          ),
          centerTitle: true,
          backgroundColor: CustomColors.primary,
          elevation: 0,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_goalTitles.length, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index; // Change page
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _selectedIndex == index
                              ? CustomColors.primary
                              : CustomColors.offWhite,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Image.asset(
                          _goalIcons[index], // Use the icon from the list
                          color: _selectedIndex == index
                              ? Colors.white
                              : CustomColors.primary,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              CustomText(
                text: _goalTitles[_selectedIndex],
                // Use the title from the list
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                squash: true,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      // Display different goals depending on what category index is selected
      body: Container(
        height: MediaQuery.of(context).size.height, // Full screen height
        color: CustomColors.offWhite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15),
              ..._buildTapCardsByCategory(_goalTitles[_selectedIndex])
                  .map((widget) => Column(
                        children: [
                          widget,
                          const SizedBox(height: 15),
                        ],
                      )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          // Navigation logic
        },
      ),
    );
  }
}

/// A page for customizing a goal, allowing the user to set specific attributes
/// like name, target, reminders, and update preferences.
class GoalCustomizationPage extends StatefulWidget {
  final bool isCustom; // Indicates if the goal is custom or predefined
  final String name; // Name of the goal (predefined or custom)
  final String category; // Goal category (e.g., 'active', 'nutrition')
  final String? unit; // Measurement unit for the goal

  const GoalCustomizationPage({
    super.key,
    required this.isCustom,
    required this.name,
    required this.category,
    this.unit,
  });

  @override
  _GoalCustomizationPageState createState() => _GoalCustomizationPageState();
}

class _GoalCustomizationPageState extends State<GoalCustomizationPage> {
  // Local variables
  String type = 'reach'; // Type of goal: 'reach' or 'avoid'
  bool intuitiveUpdate = false; // Auto-update progress based on activity
  bool reminders = false; // Whether to enable reminders
  String period = 'Daily'; // Frequency of the goal
  int target = 0; // Target value for the goal
  String? customName; // Custom name for custom goals
  String? customUnit; // Custom unit for custom goals

  // Allows user to edit the respective field attached to each controller
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isCustom) {
      customUnit = widget.unit;
    }
  }

  /// Saves the goal to Firestore and navigates back to the main goal page.
  Future<void> _saveGoal() async {
    try {
      // Prepare the goal data to be saved
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ";
      final goalData = {
        'category': widget.category,
        'complete': false,
        'details': {
          // Only active and nutrition goals can update intuitively
          if (widget.category == 'active' || widget.category == 'nutrition') 'intuitiveUpdate': intuitiveUpdate,
          'name': widget.isCustom ? customName ?? '' : widget.name,
          'period': period,
          'reminders': reminders,
          'target': target,
          'type': type,
          'units': widget.isCustom ? customUnit ?? '' : widget.unit ?? '',
        },
        'progress': 0,
        'streak': 0,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .add(goalData);

      Navigator.pop(context); // Navigate back to add goal page
      Navigator.pop(context); // Navigate back to main goal page
    } catch (e) {
      print('Error saving goal: $e');
    }
  }

  /// Builds the main UI for customizing a goal, including form inputs,
  /// sliders, and submission functionality.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // Hide the keyboard when tapping outside
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Navigate back to the add goal page
            },
            color: Colors.white,
          ),
          title: CustomText(
            text: widget.isCustom ? 'Custom Goal' : widget.name, // Set title based on goal type
            fontSize: 25.0,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            squash: true,
          ),
          centerTitle: true,
          backgroundColor: CustomColors.primary,
        ),
        body: SingleChildScrollView(
          child: Container(
            color: CustomColors.offWhite,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                if (widget.isCustom)
                // Custom name input for custom goals
                  Container(
                    margin: EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: 10),
                          child: CustomText(
                            text: 'Goal Name',
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: CustomColors.darkGray,
                            squash: true,
                          ),
                        ),
                        SizedBox(width: 60.0),
                        Container(
                          width: 150,
                          decoration: BoxDecoration(
                            color: CustomColors.primaryFaded,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            controller: _customNameController,
                            cursorColor: CustomColors.primary, // Set cursor color
                            textAlign: TextAlign.center, // Center the text
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                              color: CustomColors.darkGray, // Text color
                              letterSpacing: -0.7, // Match CustomText spacing
                              height: 0.95, // Match CustomText squash
                            ),
                            decoration: InputDecoration(
                              hintText: '', // Hint disappears when focused
                              hintStyle: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: CustomColors.darkGray, // Hint text in dark gray
                                letterSpacing: -0.7, // Match CustomText spacing
                                height: 0.95, // Match CustomText squash
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0), // Adjust padding for centering
                            ),
                            onChanged: (value) {
                              customName = value; // Update name of the goal
                            },
                            onTap: () {
                              setState(() {}); // Refresh UI to update hint text disappearance
                            },
                            onEditingComplete: () {
                              setState(() {}); // Refresh UI when editing completes
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                // Goal type selection
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Goal Type',
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.darkGray,
                        squash: true,
                      ),
                      SizedBox(height: 15.0),
                      Container(
                        decoration: BoxDecoration(
                          color: CustomColors.offWhite,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Row(
                          children: [
                            // Reach option
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  type = 'reach';
                                }),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  decoration: BoxDecoration(
                                    color: type == 'reach'
                                        ? CustomColors.primary
                                        : CustomColors.offWhite,
                                    borderRadius: BorderRadius.circular(13.0),
                                  ),
                                  child: CustomText(
                                    text: "Reach",
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: type == 'reach'
                                        ? Colors.white
                                        : CustomColors.darkGray,
                                    squash: true,
                                  ),
                                ),
                              ),
                            ),
                            // Avoid option
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  type = 'avoid';
                                }),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  decoration: BoxDecoration(
                                    color: type == 'avoid'
                                        ? CustomColors.primary
                                        : CustomColors.offWhite,
                                    borderRadius: BorderRadius.circular(13.0),
                                  ),
                                  child: CustomText(
                                    text: "Avoid",
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: type == 'avoid'
                                        ? Colors.white
                                        : CustomColors.darkGray,
                                    squash: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 10.0, bottom: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CustomText(
                            text: 'Goal Amount',
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: CustomColors.darkGray,
                            squash: true,
                          ),
                          SizedBox(width: 50),
                          Container(
                            height: 48.5,
                            constraints: BoxConstraints(
                              minWidth: 75.0, // Set a minimum width
                              maxWidth: 150.0, // Set a maximum width
                            ),
                            decoration: BoxDecoration(
                              color: CustomColors.primaryFaded,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: _targetController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center, // Center the text
                                cursorColor: CustomColors.primary, // Set cursor color
                                decoration: const InputDecoration(
                                  hintText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(left: 13.0, right: 10.0), // Optional padding
                                ),
                                onChanged: (value) {
                                  target = int.tryParse(value) ?? 0;
                                },
                                style: const TextStyle(
                                  fontSize: 17.0, // Adjust font size as needed
                                  color: CustomColors.darkGray, // Set text color to dark gray
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.7, // Set text spacing
                                  height: 0.95, // Set vertical squash
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          // Unit input for custom goals
                          if (widget.isCustom)
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(left: 1),
                                decoration: BoxDecoration(
                                  color: CustomColors.primaryFaded,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: TextField(
                                  controller: _customUnitController,
                                  cursorColor: CustomColors.primary, // Set the cursor color
                                  textAlign: TextAlign.center, // Center the text
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                    color: CustomColors.darkGray, // Set text color to dark gray
                                    letterSpacing: -0.7, // Match CustomText spacing
                                    height: 1, // Match CustomText squash
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '', // Hint disappears when focused
                                    hintStyle: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                      color: CustomColors.darkGray, // Hint text in dark gray
                                      letterSpacing: -0.6,
                                      height: 1,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0), // Reduce vertical padding
                                  ),
                                  onChanged: (value) {
                                    customUnit = value;
                                  },
                                  onTap: () {
                                    setState(() {}); // Refresh UI to handle hint text disappearance
                                  },
                                  onEditingComplete: () {
                                    setState(() {}); // Refresh UI when editing completes
                                  },
                                ),
                              ),
                            )

                          else
                            Row(
                              children: [
                                SizedBox(width: 15),
                                CustomText(
                                  text: widget.unit ?? '',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: CustomColors.darkGray,
                                  squash: true,
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(
                        height: 1.0,
                        color: CustomColors.lightGray,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          CustomText(
                            text: 'Goal Period',
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: CustomColors.darkGray,
                            squash: true,
                          ),
                          SizedBox(width: 114),
                          /* User can set a time constraint to complete a goal:
                          daily, weekly, and monthly */
                          GestureDetector(
                            onTap: () {
                              // Open option selector
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return Container(
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20.0),
                                        topRight: Radius.circular(20.0),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 10.0),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              period = 'Daily';
                                            });
                                            Navigator.pop(context); // Close the modal
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            child: CustomText(
                                              text: 'Daily',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              color: CustomColors.darkGray,
                                              squash: true,
                                            ),
                                          ),
                                        ),
                                        const Divider(thickness: 1, color: CustomColors.lightGray),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              period = 'Weekly';
                                            });
                                            Navigator.pop(context); // Close the modal
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            child: CustomText(
                                              text: 'Weekly',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              color: CustomColors.darkGray,
                                              squash: true,
                                            ),
                                          ),
                                        ),
                                        const Divider(thickness: 1, color: CustomColors.lightGray),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              period = 'Monthly';
                                            });
                                            Navigator.pop(context); // Close the modal
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            child: CustomText(
                                              text: 'Monthly',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              color: CustomColors.darkGray,
                                              squash: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: CustomColors.primaryFaded,
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: CustomText(
                                text: period,
                                color: CustomColors.darkGray,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                squash: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Option to enable reminders
                const SizedBox(height: 15),
                SliderCard(
                  text: 'Reminders',
                  isActive: reminders,
                  onActivate: () async {
                    final notificationService = NotificationService();
                    await notificationService.requestPermission();
                    setState(() {
                      reminders = true;
                    });
                  },
                  onDeactivate: () {
                    setState(() {
                      reminders = false;
                    });
                  },
                ),
                // Allow intuitive update toggle only if nutrition or active goal
                if (widget.category == 'active' || widget.category == 'nutrition')
                Column(
                  children: [
                    SizedBox(height: 15),
                    SliderCard(
                      text: 'Intuitive Update',
                      isActive: intuitiveUpdate,
                      onActivate: () {
                        setState(() {
                          intuitiveUpdate = true;
                        });
                      },
                      onDeactivate: () {
                        setState(() {
                          intuitiveUpdate = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Done',
                  onPressed: _saveGoal,
                  backgroundColor: CustomColors.primary,
                  textColor: Colors.white,
                  textSize: 18,
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
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
            // Navigation logic
          },
        ),
      ),
    );
  }
}
