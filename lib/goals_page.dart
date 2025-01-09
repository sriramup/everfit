import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/mini_info.dart';
import 'package:everfit/widgets/slider_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../colors.dart';
import '../widgets/text.dart';
import 'health_data.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  Timer? _timer;
  final HealthService _healthService = HealthService();

  // Current goal list
  List<GoalProgress> goals = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchAndUpdateGoals(); // Initial fetch
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAndUpdateGoals();
    });
  }

  Future<void> _checkCompletion(GoalProgress goal) async {
    final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
    final goalId = goal.documentID;
    final firestore = FirebaseFirestore.instance;

    final DocumentSnapshot userDoc =
    await firestore.collection('users').doc(userId).collection('goals').doc(goalId).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final progress = data['progress'];
      final details = data['details'] as Map<String, dynamic>;
      final target = details['target'];
      final type = details['type']; // New field
      final complete = data['complete'];

      bool isComplete;
      if (type == 'avoid') {
        isComplete = progress < target;
      } else if (type == 'reach') {
        isComplete = progress >= target;
      } else {
        return; // Skip if type is invalid or undefined
      }

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

          // Mark as complete and increment streak
          await firestore
              .collection('users')
              .doc(userId)
              .collection('goals')
              .doc(goalId)
              .update({'complete': true, 'streak': currentStreak + 1});
        }
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

          // Mark as complete and increment streak
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

  Future<void> _updateIntuitive(GoalProgress goal) async {
    if (goal.category == 'activity') {
      try {
        String goalName = goal.details['name'];
        dynamic fetchedData;

        if (goalName.toLowerCase().contains('steps')) {
          fetchedData = await _healthService.fetchTotalStepsToday();
        } else if (goalName.toLowerCase().contains('calories')) {
          fetchedData = await _healthService.fetchActiveCaloriesToday();
        } else if (goalName.toLowerCase().contains('travel')) {
          fetchedData = (await _healthService.fetchDistanceToday())! * 0.000621371; // Convert to miles
        } else {
          print('No matching health data logic for goal: $goalName');
          return;
        }

        final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
        final goalId = goal.documentID;
        final firestore = FirebaseFirestore.instance;

        final DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).collection('goals').doc(goalId).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final previousData = data['progress'];

          await firestore
              .collection('users')
              .doc(userId)
              .collection('goals')
              .doc(goalId)
              .update({'progress': previousData + (fetchedData - previousData)});
        }
      } catch (e) {
        print('Error fetching goal-specific data: $e');
      }
    }
  }

  Future<void> _fetchAndUpdateGoals() async {
    try {
      final fetchedGoals = await _fetchGoals();
      for (GoalProgress g in fetchedGoals) {
        if (g.details['intuitiveUpdate'] != null) {
          if (g.details['intuitiveUpdate']) {
            _updateIntuitive(g);
          }
        }
        _checkCompletion(g);
      }

      if (_isGoalListChanged(fetchedGoals, goals)) {
        setState(() {
          goals = fetchedGoals;
        });
      }
    } catch (e) {
      print('Error fetching goals: $e');
    }
  }

  bool _isGoalListChanged(List<GoalProgress> newList, List<GoalProgress> currentList) {
    if (newList.length != currentList.length) {
      return true;
    }

    for (int i = 0; i < newList.length; i++) {
      if (newList[i].progress != currentList[i].progress ||
          newList[i].details['reminders'] != currentList[i].details['reminders'] ||
          newList[i].details['intuitiveUpdate'] != currentList[i].details['intuitiveUpdate'] ||
          newList[i].complete != currentList[i].complete) {
        return true;
      }
    }
    return false;
  }

  Future<List<GoalProgress>> _fetchGoals() async {
    final List<GoalProgress> fetchedGoals = [];

    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...goals.map((goal) => goal),
        const MiniInfo(text: 'Tap and hold to remove a goal'),
      ]),
    );
  }
}

class GoalProgress extends StatelessWidget {
  final Map<String, dynamic>? analysis;
  final String category;
  final bool complete;
  final Map<String, dynamic> details;
  final int progress;
  final int target;
  final int streak;
  final String documentID;
  final VoidCallback onDelete;

  const GoalProgress({
    super.key,
    this.analysis,
    required this.category,
    required this.complete,
    required this.details,
    required this.progress,
    required this.target,
    required this.streak,
    required this.documentID,
    required this.onDelete,
  });

  Future<void> _deleteGoal(BuildContext context) async {
    try {
      final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(documentID)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal deleted successfully')),
      );

      onDelete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting goal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (progress / target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoalDetailPage(
              goal: GoalProgress(
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
        await _deleteGoal(context);
      },
        child: Column(
          children: [
            if (complete)
              SizedBox(height: 15.0),
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
                            CircleAvatar(
                              radius: 20.0,
                              backgroundColor: CustomColors.primaryFaded,
                              child: Icon(
                                category == 'activity'
                                    ? Icons.local_fire_department
                                    : Icons.local_drink,
                                color: CustomColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            CustomText(
                              text: details['name'] ?? 'Unnamed Goal',
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: CustomColors.darkGray,
                              squash: true,
                            ),
                            const SizedBox(width: 10.0),
                            if (streak > 0)
                              Expanded(
                                child: CustomText(
                                  text: "🔥 $streak",
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                  squash: true,
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: CustomColors.primaryFaded,
                                borderRadius: BorderRadius.circular(13.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 9.0),
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
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0),
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



class GoalDetailPage extends StatefulWidget {
  final GoalProgress goal;

  const GoalDetailPage({super.key, required this.goal});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late int progress;
  final TextEditingController _progressController = TextEditingController(); // Add this
  final FocusNode _progressFocusNode = FocusNode(); // Add FocusNode

  @override
  void initState() {
    super.initState();
    progress = widget.goal.progress;
    _progressController.text = progress.toString(); // Initialize the controller

    // Add a listener to handle focus changes
    _progressFocusNode.addListener(() {
      if (!_progressFocusNode.hasFocus) {
        // If the TextField loses focus, call updateProgress
        final int? newProgress = int.tryParse(_progressController.text);
        if (newProgress != null && newProgress >= 0) {
          _updateProgress(newProgress);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid progress value. Please enter a valid number.'),
            ),
          );
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

  void _updateProgress(int newProgress) async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(widget.goal.documentID)
          .update({'progress': newProgress});

      setState(() {
        progress = newProgress;
        _progressController.text = newProgress.toString();
      });
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  void _updateReminders(bool reminders) async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
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

  void _updateIntuitive(bool intuitiveUpdate) async {
    try {
      final String userId =
          "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID
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

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (progress / widget.goal.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hides the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
            text: widget.goal.details['name'] ?? 'Goal Detail',
            fontSize: 25.0,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            squash: true,
          ),
          centerTitle: true,
        ),
        body: Container(
          color: CustomColors.offWhite,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
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
                        child: CircularPercentIndicator(
                          radius: 130.0,
                          lineWidth: 20.0,
                          percent: progressPercentage,
                          center: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              Padding(
                                padding: const EdgeInsets.only(top: 100.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 110, // Makes the TextField take full width of the parent
                                      decoration: BoxDecoration(
                                        color: CustomColors.primaryFaded,
                                        borderRadius: BorderRadius.circular(13.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30.0),
                                        child: TextField(
                                          cursorColor: CustomColors.primary,
                                          focusNode: _progressFocusNode, // Assign FocusNode
                                          controller: _progressController, // Set the controller
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly, // Only allow digits
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
                                          onSubmitted: (value) async {
                                            final int? newProgress = int.tryParse(value);
                                            if (newProgress != null && newProgress >= 0) {
                                              _updateProgress(newProgress); // Update progress
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Invalid progress value. Please enter a valid number.',
                                                  ),
                                                ),
                                              );
                                              _progressController.text = progress.toString(); // Reset to the last valid value
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
                SliderCard(
                  text: 'Reminders',
                  onActivate: () {
                    _updateReminders(true);
                    widget.goal.details['reminders'] = true;
                  },
                  onDeactivate: () {
                    _updateReminders(false);
                    widget.goal.details['reminders'] = false;
                  },
                  isActive: widget.goal.details['reminders'],
                ),
                const SizedBox(height: 15.0),
                if (widget.goal.details['intuitiveUpdate'] != null)
                  Column(
                    children: [
                      SliderCard(
                        text: 'Intuitive Update',
                        onActivate: () {
                          _updateIntuitive(true);
                          widget.goal.details['intuitiveUpdate'] = true;
                        },
                        onDeactivate: () {
                          _updateIntuitive(false);
                          widget.goal.details['intuitiveUpdate'] = false;
                        },
                        isActive: widget.goal.details['intuitiveUpdate'],
                      ),
                      const SizedBox(height: 15.0),
                    ],
                  ),
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
            // Add navigation logic if needed
          },
        ),
      ),
    );
  }
}

class AddGoalPage extends StatelessWidget {
  const AddGoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Goal'),
        backgroundColor: CustomColors.primary,
      ),
      body: const Center(
        child: Text('Add Goal Page'),
      ),
    );
  }
}
