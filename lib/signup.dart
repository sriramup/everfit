import 'package:flutter/material.dart';
import 'colors.dart';
import 'widgets/button.dart'; // Import your CustomButton class

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<SignupPage> {
  // Create TextEditingControllers to capture user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State to control password visibility
  bool _obscureText = true;

  @override
  void dispose() {
    // Dispose of the controllers when the widget is removed
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleSignup() {
    // Retrieve email and password
    String email = emailController.text;
    String password = passwordController.text;

    // Debugging: Print the values (replace this with your login logic)
    print('Email: $email');
    print('Password: $password');

    // Add your authentication logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        // Dismiss keyboard when tapping outside of a text field
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png', // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
            // Foreground content
            Positioned.fill(
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45.0),
                  ),
                  elevation: 0, // No shadow
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
                            // Hide keyboard and go back
                            FocusScope.of(context).unfocus();
                            await Future.delayed(const Duration(milliseconds: 150));
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(height: 10),
                        // EverFit and Squashed Log In
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
                                transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0), // Squashed text
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
                        // Email TextField
                        TextField(
                          controller: emailController, // Connect the controller
                          decoration: InputDecoration(
                            labelText: 'Enter email ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 25.0,
                              horizontal: 20.0,
                            ), // Adjust
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: CustomColors.primary, // Custom color
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Password TextField
                        TextField(
                          controller: passwordController, // Connect the controller
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
                            ), // Adjust
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: CustomColors.primary, // Custom color
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 192),
                        // Log In Button using CustomButton
                        CustomButton(
                          text: 'Sign Up',
                          onPressed: handleSignup, // Call handleSignup on press
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