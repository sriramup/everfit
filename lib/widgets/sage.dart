import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/text.dart'; // CustomText widget
import '../colors.dart';

/// A chat interface for interacting with "Sage," a health and fitness-related assistant powered by OpenAI's GPT 3.5 turbo model.
class SagePage extends StatefulWidget {
  const SagePage({super.key});

  @override
  State<SagePage> createState() => _SagePageState();
}

class _SagePageState extends State<SagePage> {
  // Controller for the user's message input field
  final TextEditingController _messageController = TextEditingController();

  // Chat history: a list of messages containing role (user/assistant) and content
  final List<Map<String, String>> _messages = [];

  // Loading state to indicate when a message is being processed
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Add an initial greeting message from the assistant
    _messages.add({
      'role': 'assistant',
      'content': 'How may I help you today?',
    });
  }

  @override
  void dispose() {
    _messageController.dispose(); // Dispose of the controller when not in use
    super.dispose();
  }

  /// Sends a user's message to the assistant and retrieves a response.
  Future<void> _sendMessage(String message) async {
    setState(() {
      _isLoading = true; // Show loading indicator
      _messages.add({'role': 'user', 'content': message}); // Add user's message to the chat history
    });

    try {
      // Make a POST request to the OpenAI API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer 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', // Replace with your OpenAI API key
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
              'You are a helpful assistant that gives advice related to the user\'s health and fitness-related questions.',
            },
            ..._messages.map((msg) => {
              'role': msg['role'],
              'content': msg['content'],
            })
          ],
        }),
      );

      if (response.statusCode == 200) {
        // Parse the API response
        final data = json.decode(response.body);
        final chatResponse = data['choices'][0]['message']['content'];

        setState(() {
          // Add the assistant's response to the chat history
          _messages.add({'role': 'assistant', 'content': chatResponse});
        });
      } else {
        // Handle errors from the API
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Sorry, I could not process your request.',
          });
        });
      }
    } catch (e) {
      // Handle network or other errors
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'An error occurred. Please try again later.',
        });
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
        _messageController.clear(); // Clear the input field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0; // Check if the keyboard is visible

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing when the keyboard opens
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            FocusScope.of(context).unfocus(); // Hide the keyboard
            Navigator.pop(context); // Navigate back
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
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    reverse: isKeyboardVisible, // Reverse the order when keyboard is visible
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
                                  child: Image.asset('assets/images/sage.png'),
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
          // Message input field and send button
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            ),
            padding: const EdgeInsets.only(
                left: 20.0, right: 20.0, top: 5.0, bottom: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    cursorColor: CustomColors.primary,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.darkGray,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Message Sage",
                      hintStyle: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.gray,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: CustomColors.primary),
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

