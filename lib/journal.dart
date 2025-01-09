import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/widgets/mini_info.dart';
import 'package:everfit/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Install the package for the calendar widget
import 'colors.dart';
import 'globals.dart' as globals; // Import your globals file

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  DateTime _focusedDate = DateTime.now(); // Default to the current date
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    // Update the focused date if `globals.newDay` is true
    if (globals.newDay) {
      _focusedDate = _focusedDate.add(const Duration(days: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to Home
          },
          color: Colors.white,
        ),
        title: CustomText(
          text: 'Journal',
          fontSize: 25.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
          textHeight: 0.8,
        ),
        centerTitle: true,
        backgroundColor: CustomColors.primary,
      ),
      body: Container(
        color: CustomColors.offWhite,
        child: Column(
          children: [
            const SizedBox(height: 15),
            // Calendar Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDate,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDate, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDate = focusedDay; // Update focused day
                    });
                    // Navigate to the Journal Entry Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            JournalEntryPage(date: selectedDay),
                      ),
                    );
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: CustomColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: CustomColors.gray,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(
                      color: CustomColors.darkGray,
                      fontSize: 16.0,
                      fontFamily: 'Poppins',
                    ),
                    outsideTextStyle: TextStyle(
                      color: CustomColors.gray,
                      fontSize: 14.0,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: CustomColors.darkGray,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      letterSpacing: -0.5,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: CustomColors.darkGray,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: CustomColors.darkGray,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: MiniInfo(text: 'Tap on a date to open its journal entry'),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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

class JournalEntryPage extends StatefulWidget {
  final DateTime date;

  const JournalEntryPage({Key? key, required this.date}) : super(key: key);

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with the actual user ID

  bool isToday = false; // Flag to check if the page is for today's journal
  String? documentId; // Document ID for the selected journal entry

  @override
  void initState() {
    super.initState();
    isToday = _isToday(widget.date);
    _fetchJournalEntry();
  }

  @override
  void dispose() {
    _moodController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _fetchJournalEntry() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('entries')
          .where('today', isEqualTo: isToday)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        documentId = doc.id;

        final data = doc.data();
        _moodController.text = data['mood'] ?? "Mood";
        _bodyController.text = data['body'] ?? "Type something";
      }
    } catch (e) {
      print('Error fetching journal entry: $e');
    }
  }

  Future<void> _updateJournalEntry(String field, String value) async {
    if (documentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(documentId)
          .update({field: value});
    } catch (e) {
      print('Error updating journal entry: $e');
    }
  }

  Future<void> _handleBackNavigation() async {
    // Retract the keyboard
    FocusScope.of(context).unfocus();

    // Wait a few milliseconds
    await Future.delayed(const Duration(milliseconds: 100));

    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = "${_getMonthName(widget.date.month)} ${widget.date.day}, ${widget.date.year}";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackNavigation, // Custom back button behavior
          color: Colors.white,
        ),
        title: CustomText(
          text: formattedDate,
          fontSize: 25.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
          textHeight: 0.8,
        ),
        centerTitle: true,
        backgroundColor: CustomColors.primary,
      ),
      body: Container(
        color: CustomColors.offWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              cursorColor: CustomColors.primary,
              controller: _moodController,
              onChanged: (value) => _updateJournalEntry('mood', value),
              style: TextStyle(
                fontSize: 40.0,
                fontWeight: FontWeight.w800,
                color: CustomColors.darkGray,
                height: 0.8,
                letterSpacing: -0.7,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: TextField(
                cursorColor: CustomColors.primary,
                controller: _bodyController,
                onChanged: (value) => _updateJournalEntry('body', value),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: CustomColors.darkGray,
                  height: 0.8,
                  letterSpacing: -0.7,
                ),
                decoration: const InputDecoration(
                  hintText: "Type something...",
                  hintStyle: TextStyle(
                    color: CustomColors.gray,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
