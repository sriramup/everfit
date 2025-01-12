import 'package:everfit/forgot_password.dart';
import 'package:everfit/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';
import 'layout.dart';
import 'widgets/button.dart';

// Checks if user account exists to load relevant data
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Create TextEditingControllers to capture user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Hide password toggle
  bool _obscureText = true;
  // Tracks if the password entered doesn't match the stored password
  bool _passwordFieldError = false;
  String? _passwordErrorMessage;

  @override
  void dispose() {
    // Ensure memory is cleaned up when the widget is disposed
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    final firestore = FirebaseFirestore.instance;

    try {
      // Check if the user's email exists in the database
      final userSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        // Extract user details from the database
        final userData = userSnapshot.docs.first.data();
        String storedPassword = userData['password'];

        if (storedPassword == password) {
          // If password matches, navigate to the main page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        } else {
          // If the password is incorrect, show an error on the password field
          setState(() {
            _passwordFieldError = true;
            _passwordErrorMessage = 'Incorrect password'; // Display error message
          });
        }
      } else {
        // If no account matches the email, show a notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with this email.')),
        );
      }
    } catch (e) {
      // Show an error notification in case of a database or network issue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents layout changes when keyboard appears
      body: GestureDetector(
        onTap: () {
          // Hide the keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Background image for the login screen
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45.0),
                  ),
                  elevation: 0, // Flat appearance for the card
                  color: Colors.white,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 50,
                    height: MediaQuery.of(context).size.height - 100,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: CustomColors.black,
                            size: 30,
                          ),
                          onPressed: () async {
                            // Delay navigation to give feedback on the button press
                            FocusScope.of(context).unfocus();
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(height: 10),
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
                              'Log In',
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
                        SizedBox(height: 75),
                        // Email input field
                        TextField(
                          controller: emailController,
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
                        // Password input field
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText, // Toggles visibility of the password
                          decoration: InputDecoration(
                            labelText: 'Enter password',
                            suffixIcon: IconButton(
                              // Toggles password visibility
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
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
                                color: _passwordFieldError
                                    ? Colors.red // Show red border if password is incorrect
                                    : CustomColors.primary,
                                width: 2.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: _passwordFieldError
                                    ? Colors.red // Show red border if password is incorrect
                                    : Colors.grey,
                                width: 1.5,
                              ),
                            ),
                            errorText:
                            _passwordFieldError ? _passwordErrorMessage : null, // Displays message if password is incorrect
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          onChanged: (value) {
                            // Clear error state when the user starts typing again
                            setState(() {
                              _passwordFieldError = false;
                              _passwordErrorMessage = null; // Reset error message
                            });
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordPage(email: emailController.text),
                                ),
                              );
                            },
                            child: CustomText(
                              text: 'Forget Password ?',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CustomColors.black,
                              squash: true,
                            ),
                          ),
                        ),
                        // Adjust button position based on error visibility
                        _passwordFieldError ? SizedBox(height: 120) : SizedBox(height: 145),
                        CustomButton(
                          text: 'Log In',
                          onPressed: handleLogin, // Validates login information
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
