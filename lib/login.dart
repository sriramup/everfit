import 'package:everfit/forgot_password.dart';
import 'package:everfit/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';
import 'layout.dart';
import 'widgets/button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _passwordFieldError = false;
  String? _passwordErrorMessage; // Store the error message dynamically

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    final firestore = FirebaseFirestore.instance;

    try {
      final userSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        String storedPassword = userData['password'];

        if (storedPassword == password) {
          // Password is correct, navigate to MainPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        } else {
          // Password is incorrect, show error
          setState(() {
            _passwordFieldError = true;
            _passwordErrorMessage = 'Incorrect password'; // Set error message
          });
        }
      } else {
        // No user found with the given email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with this email.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
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
                  elevation: 0,
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
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Enter password',
                            suffixIcon: IconButton(
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
                                    ? Colors.red
                                    : CustomColors.primary,
                                width: 2.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: _passwordFieldError
                                    ? Colors.red
                                    : Colors.grey,
                                width: 1.5,
                              ),
                            ),
                            errorText:
                            _passwordFieldError ? _passwordErrorMessage : null,
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          onChanged: (value) {
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
                                MaterialPageRoute(builder: (context) => ForgotPasswordPage(email: emailController.text)),
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
                        _passwordFieldError ? SizedBox(height: 120) : SizedBox(height: 145),
                        CustomButton(
                          text: 'Log In',
                          onPressed: handleLogin,
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
