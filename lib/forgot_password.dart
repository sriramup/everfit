import 'dart:math';
import 'package:everfit/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'colors.dart';
import 'widgets/button.dart'; // Import your CustomButton class

class ForgotPasswordPage extends StatefulWidget {
  final String email; // Email passed from the LoginPage

  const ForgotPasswordPage({super.key, required this.email});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late String _generatedCode; // Randomly generated code
  final List<TextEditingController> _codeControllers =
  List.generate(4, (_) => TextEditingController()); // 4 controllers for OTP fields

  @override
  void initState() {
    super.initState();
    _generatedCode = _generateRandomCode(); // Generate random 4-digit code
    _sendRecoveryEmail(); // Send the email with the code
  }

  @override
  void dispose() {
    // Dispose controllers
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _generateRandomCode() {
    final random = Random();
    return List.generate(4, (_) => random.nextInt(10)).join(); // Generate 4 random digits
  }

  Future<void> _sendRecoveryEmail() async {
    final smtpServer = gmail('noreply.everfit@gmail.com', 'Camp@8134'); // Your email credentials
    final message = Message()
      ..from = Address('noreply.everfit@gmail.com', 'EverFit') // Your app name
      ..recipients.add(widget.email) // Recipient email
      ..subject = 'Password Recovery Code'
      ..text = 'Your recovery code is: $_generatedCode'; // Email body

    try {
      await send(message, smtpServer);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 1500),
            content: CustomText(text:'Recovery email sent successfully.', fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white, squash: true,)
        ),
      );
    }
  }

  void _verifyCode() {
    final enteredCode =
    _codeControllers.map((controller) => controller.text).join(); // Combine inputs

    if (enteredCode == _generatedCode) {
      // Navigate or show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code verified successfully!')),
      );
      // TODO: Navigate to the next page
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
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
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(height: 10),
                      // Check your email text
                      CustomText(
                        text: 'Check your email',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: CustomColors.black,
                        squash: true,
                      ),
                      SizedBox(height: 10),
                      // Description text
                      CustomText(
                        text: 'We sent a reset code to ',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.gray,
                        squash: true,
                      ),
                      CustomText(
                        text: widget.email,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.darkGray,
                        squash: true,
                      ),
                      SizedBox(height: 5),
                      CustomText(
                        text: 'Enter the 4 digit code that is given in the email',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.gray,
                        squash: true,
                      ),
                      SizedBox(height: 25),
                      // OTP Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                              (index) => SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _codeControllers[index],
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                counterText: '', // Hide counter
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: CustomColors.primary, // Custom color
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Verify Code Button
                      CustomButton(
                        text: 'Verify Code',
                        onPressed: _verifyCode, // Verify code logic
                        backgroundColor: CustomColors.primary,
                      ),
                      SizedBox(height: 20),
                      // Resend Email
                      Center(
                        child: Column(
                          children: [
                            CustomText(
                              text: "Haven't got the email yet?",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CustomColors.black,
                              squash: true,
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _generatedCode = _generateRandomCode(); // Generate new code
                                });
                                _sendRecoveryEmail(); // Resend email
                              },
                              child: CustomText(
                                text: 'Resend email',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CustomColors.primary,
                                squash: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}