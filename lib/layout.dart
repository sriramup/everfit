import 'package:flutter/material.dart';
import 'badges_page.dart';
import 'colors.dart'; // Your custom colors
import 'app_bar.dart';
import 'discover_page.dart';
import 'goals_page.dart';
import 'home_page.dart';
import 'settings_page.dart';


/// Uniform layout of the app that maps each page to navigation bar icons
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  /// Define the pages with their respective titles and subtitle statuses
  List<Map<String, dynamic>> _pages = [];

  @override
  void initState() {
    super.initState();
    /// Assign a page to an index
    _pages = [
      {
        'title': 'Home',
        'body': HomePage(),
        'subtitle': true,
        'add' : false,
      },
      {
        'title': 'Goals',
        'body': GoalsPage(),
        'subtitle': false,
        'add' : true,
      },
      {
        'title': 'Badges',
        'body': BadgesPage(),
        'subtitle': false,
        'add' : false,
      },
      {
        'title': 'Discover',
        'body': DiscoverPage(),
        'subtitle': false,
        'add' : false,
      },
      {
        'title': 'Settings',
        'body': SettingsPage(),
        'subtitle': false,
        'add' : false,

      },
    ];
  }

  /// Change what page is being viewed without sliding
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomAppBar(
        title: _pages[_currentIndex]['title'],
        subtitle: _pages[_currentIndex]['subtitle'],
        add: _pages[_currentIndex]['add'],
        body: IndexedStack( /// Allows the state of each page to be preserved
          index: _currentIndex,
          children: <Widget>[
            HomePage(),
            GoalsPage(),
            BadgesPage(),
            DiscoverPage(),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, /// Updates index
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
      ),
    );
  }
}