import 'package:everfit/firebase_options.dart';
import 'package:everfit/home_page.dart';
import 'package:everfit/layout.dart';
import 'package:everfit/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'colors.dart';
import 'login.dart';
import 'globals.dart' as globals;
import 'widgets/button.dart';
import 'package:intl/intl.dart';

/// Entry point of the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  globals.currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

  // Check if day passed since last login to refresh page content
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('last_login_date') != null && globals.currentDate != prefs.getString('last_login_date')) {
    globals.newDay = true;
  } else {
    globals.newDay = false;
  }

  // Establish connection with backend service
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Allow read access to Apple Health data
  Health().configure();

  // Lock screen in portrait mode (upright)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(
        AppLifecycleHandler( // Performs the check to validate new day
          child: MyApp(prefs: prefs),
        )
    );
  });
}

/// Prompts app to open and load first screen
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Check if skipLogin option enabled in app settings
    bool? skipLogin = prefs.getBool('skipLogin');
    return MaterialApp(
      title: 'Everfit',
      theme: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: CustomColors.primary),
        useMaterial3: true,
      ),
      // Skip to main page if skipLogin enabled
      home: skipLogin != null && skipLogin ? MainPage() : StartupPage(),
    );
  }
}

/// Welcome page for users to get started
class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Widgets on top of the image
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45.0),
                  ),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        width: size.width - 50,
                        height: size.height - 100,
                        padding: EdgeInsets.all(20.0),
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.all(30.0),
                              child: Transform(
                                transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0), // Squash text vertically
                                alignment: Alignment.topCenter,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Welcome to',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 27,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.7,
                                        color: CustomColors.black,
                                      ),
                                    ),
                                    Text(
                                      'EverFit',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 27,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.7,
                                        color: CustomColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: FractionallySizedBox(
                                // Set width to 70% of the card
                                widthFactor: 0.7,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'WHERE WELLNESS TAKES ROOT',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 35,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.7,
                                  color: CustomColors.black,
                                ),
                              ),
                            ),
                            SizedBox(
                                height: 60
                            ),
                            CustomButton(
                              text: 'Log In',
                              onPressed: () {
                                // Opens the log in page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginPage()),
                                );
                              },
                              backgroundColor: CustomColors.primary,
                            ),
                            SizedBox(
                                height: 20
                            ),
                            CustomButton(
                              text: 'Create An Account',
                              backgroundColor: CustomColors.offWhite,
                              textColor: Colors.black,
                              onPressed: () {
                                // Opens the sign up page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SignupPage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Checks if app is terminating and saves relevant data to cache
class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({Key? key, required this.child}) : super(key: key);

  @override
  _AppLifecycleHandlerState createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  /// Save previous login date before app terminates
  Future<void> saveLoginDateBeforeTermination() async {
    final prefs = await SharedPreferences.getInstance();
    // Set current login date as previous login date
    await prefs.setString('last_login_date', globals.currentDate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      saveLoginDateBeforeTermination();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
