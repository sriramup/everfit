import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/home_page.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'widgets/button.dart';

/// Allows users to create credentials that store user-specific data
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Create TextEditingControllers to capture user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State to control password visibility
  bool _obscureText = true;

  @override
  void dispose() {
    // Dispose of the controllers when the page changes
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleSignup() async {
    // Store user inputted email and password
    String email = emailController.text;
    String password = passwordController.text;

    // Structure data to adhere to database schema
    final credentials = {
      'email': email,
      'password': password,
    };

    // Add new user to database
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .add(credentials);

    // Go to home page
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Avoid screen resize when keyboard opened
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        // Dismiss keyboard when tapping outside of a text field
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
            // Foreground widget layout
            Positioned.fill(
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45.0),
                  ),
                  elevation: 0, // No  button shadow
                  color: Colors.white,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 50,
                    height: MediaQuery.of(context).size.height - 100,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Arrow
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: CustomColors.black,
                            size: 30,
                          ),
                          onPressed: () async {
                            // Hide keyboard and go to previous page
                            FocusScope.of(context).unfocus();
                            await Future.delayed(const Duration(milliseconds: 150));
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform(
                              transform: Matrix4.diagonal3Values(1.0, 1, 1.0),
                              child: Text(
                                'EverFit',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 60,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.7,
                                  color: CustomColors.primary,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Transform(
                                transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 25,
                                    letterSpacing: -0.7,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 75),
                        // Allows email field to be inputted by user
                        TextField(
                          controller: emailController, // Allow user to modify
                          decoration: InputDecoration(
                            labelText: 'Enter email ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 25.0,
                              horizontal: 20.0,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: CustomColors.primary,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Allows password field to be inputted by user
                        TextField(
                          controller: passwordController, // Allow user to modify
                          obscureText: _obscureText, // Control visibility
                          decoration: InputDecoration(
                            labelText: 'Create password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off // Hidden state
                                    : Icons.visibility, // Visible state
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText; // Toggle state
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 25.0,
                              horizontal: 20.0,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: CustomColors.primary,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 192),
                        CustomButton(
                          text: 'Sign Up',
                          onPressed: handleSignup, // Save credentials
                          backgroundColor: CustomColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}