import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/text.dart'; // CustomText widget
import '../colors.dart';

class SagePage extends StatefulWidget {
  const SagePage({super.key});

  @override
  State<SagePage> createState() => _SagePageState();
}

class _SagePageState extends State<SagePage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Chat history
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial message from Sage
    _messages.add({
      'role': 'assistant',
      'content': 'How may I help you today?',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'content': message});
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer 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', // Your API key
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
              'You are a helpful assistant that gives advice related to the user\'s health and fitness-related questions.'
            },
            ..._messages.map((msg) => {
              'role': msg['role'],
              'content': msg['content'],
            })
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chatResponse = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({'role': 'assistant', 'content': chatResponse});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Sorry, I could not process your request.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'An error occurred. Please try again later.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing when the keyboard opens
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            FocusScope.of(context).unfocus(); // Ensure the keyboard retracts
            Navigator.pop(context); // Navigate back after a small delay
          },
          color: Colors.white,
        ),
        title: const CustomText(
          text: 'Sage',
          fontSize: 25.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
          textHeight: 0.8,
        ),
        centerTitle: true,
        backgroundColor: CustomColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 15), // Fixed padding before messages
                Expanded(
                  child: ListView.builder(
                    reverse: isKeyboardVisible, // Reverse only when keyboard is visible
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = isKeyboardVisible
                          ? _messages[_messages.length - 1 - index]
                          : _messages[index];
                      final isUser = message['role'] == 'user';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isUser)
                              CircleAvatar(
                                backgroundColor: CustomColors.turquoise,
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child:
                                  Image.asset('assets/images/sage.png'),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 15.0),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? CustomColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: CustomText(
                                  text: message['content'] ?? '',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isUser
                                      ? Colors.white
                                      : CustomColors.darkGray,
                                  squash: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15.0),
                topRight: const Radius.circular(15.0),
              ),
            ),
            padding: const EdgeInsets.only(
                left: 20.0, right: 20.0, top: 5.0, bottom: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Transform(
                    transform: Matrix4.diagonal3Values(1.0, 0.95, 1.0),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _messageController,
                      cursorColor: CustomColors.primary, // Cursor color
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.7,
                        color: CustomColors.darkGray, // Text color
                      ),
                      decoration: const InputDecoration(
                        hintText: "Message Sage",
                        hintStyle: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.7,
                          color: CustomColors.gray,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: CustomColors.primary),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _sendMessage(_messageController.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
