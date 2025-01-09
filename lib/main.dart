import 'package:everfit/firebase_options.dart';
import 'package:everfit/home_page.dart';
import 'package:everfit/layout.dart';
import 'package:everfit/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'colors.dart';
import 'login.dart';
import 'globals.dart' as globals;
import 'widgets/button.dart';
import 'package:intl/intl.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  globals.currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
  final prefs = await SharedPreferences.getInstance();
  // if (prefs.getString('last_login_date') != null && globals.currentDate != prefs.getString('last_login_date')) {
  //   globals.newDay = true;
  // } else {
  //   globals.newDay = false;
  // }
  globals.newDay = false; // delete later
  prefs.setBool('is_health_authorized', false);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Health().configure();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Portrait mode (upright)
  ]).then((_) {
    runApp(
        AppLifecycleHandler(
          child: const MyApp(),
        )
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everfit',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: CustomColors.primary),
        useMaterial3: true,
      ),
      // home: StartupPage(),
      home: MainPage(),
    );
  }
}

class StartupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', // Replace with your image path
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
                                transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0), // Squash vertically
                                alignment: Alignment.topCenter,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Welcome to',
                                      style: TextStyle(
                                        fontFamily: 'Poppins', // Use your custom font here
                                        fontSize: 27,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.7,
                                        color: CustomColors.black,
                                      ),
                                    ),
                                    Text(
                                      'EverFit',
                                      style: TextStyle(
                                        fontFamily: 'Poppins', // Use your custom font here
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
                            // Adjusted logo image with custom padding
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: FractionallySizedBox(
                                widthFactor: 0.7, // Set width to 80% of the card
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/images/logo.png', // Replace with your image path
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
                                  fontFamily: 'Poppins', // Use your custom font here
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
                            // Custom Buttons
                            CustomButton(
                              text: 'Log In',
                              onPressed: () {
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

  // Save the previous login date before the app terminates
  Future<void> saveLoginDateBeforeTermination() async {
    final prefs = await SharedPreferences.getInstance();
    // Set the current login date as the previous login date
    await prefs.setString('last_login_date', globals.currentDate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      // Save the login date when the app is closing or going to the background
      saveLoginDateBeforeTermination();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
