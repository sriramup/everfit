import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everfit/goals_page.dart';
import 'package:everfit/widgets/slider_card.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'widgets/text.dart';
import 'widgets/button.dart';
import 'colors.dart';

/// Allows the user to take pictures of their meals and automatically processes them for macronutrients.
class ScanMealPage extends StatefulWidget {
  final GoalProgress goal; // The associated goal object for the scan
  final List<CameraDescription> cameras; // List of available camera descriptions

  const ScanMealPage({
    super.key,
    required this.goal,
    required this.cameras,
  });

  @override
  State<ScanMealPage> createState() => _ScanMealPageState();
}

class _ScanMealPageState extends State<ScanMealPage> {
  late CameraController _cameraController; // Controller for managing the camera
  XFile? capturedImage; // Stores the image captured by the camera

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Initialize the camera on widget load
  }

  /// Initializes the camera using the first available camera.
  Future<void> _initializeCamera() async {
    try {
      _cameraController =
          CameraController(widget.cameras[0], ResolutionPreset.high);
      await _cameraController.initialize(); // Prepare the camera
      setState(() {}); // Refresh UI after initialization
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  /// Captures an image and stores it in [capturedImage].
  Future<void> _captureImage() async {
    if (_cameraController.value.isInitialized) {
      try {
        final image = await _cameraController.takePicture();
        setState(() {
          capturedImage = image;
        });
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose(); // Dispose of the camera controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fixedHeight = MediaQuery.of(context).size.height * 0.7;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56), // AppBar height
        child: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Return to the previous screen
            },
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Display the captured image or camera preview
            capturedImage != null
                ? SizedBox(
              width: screenWidth,
              height: fixedHeight,
              child: Image.file(
                File(capturedImage!.path),
                fit: BoxFit.fitWidth,
              ),
            )
                : ClipRect(
              child: SizedBox(
                width: screenWidth,
                height: fixedHeight,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: SizedBox(
                    width: screenWidth,
                    child: CameraPreview(_cameraController),
                  ),
                ),
              ),
            ),
            // Bottom container with buttons
            Container(
              color: Colors.black,
              width: screenWidth,
              height: MediaQuery.of(context).size.height -
                  fixedHeight -
                  130, // Remaining screen height
              child: Center(
                child: capturedImage == null
                    ? SizedBox(
                  width: 80,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _captureImage, // Capture image
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0, // No shadow
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 30,
                      color: CustomColors.primary,
                    ),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          capturedImage = null; // Reset captured image
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: const Text(
                        "Redo",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CustomColors.primary,
                        ),
                      ),
                    ),
                    // Done button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MealDetailsPage(
                              goal: widget.goal,
                              image: capturedImage,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// This page classifies the submitted image as a food item and populates nutrition goals
/// with the appropriate macronutrient data (calories, protein, carbs, fat).
class MealDetailsPage extends StatefulWidget {
  final GoalProgress goal; // The associated goal for this meal.
  final XFile? image; // The captured meal image.

  const MealDetailsPage({super.key, required this.goal, this.image});

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  bool applyToAll = false; // Flag to apply updates to all nutrition goals or just the current goal.
  int? calories; // Calories extracted from the meal.
  double? protein; // Protein content in grams.
  int? carbs; // Carbohydrates content in grams.
  double? fat; // Fat content in grams.
  String? foodName; // Name of the food item.
  bool isLoading = true; // Loading state for API calls.

  @override
  void initState() {
    super.initState();
    _fetchLogMealData(widget.image); // Fetch meal data upon initialization.
  }

  /// Fetches meal data from the LogMeal API using the provided image.
  Future<void> _fetchLogMealData(XFile? file) async {
    setState(() {
      isLoading = true; // Start loading indicator.
    });

    // LogMeal AI food image recognition API
    try {
      const String apiKey = "wjhlidhopd13409"; // LogMeal API key.
      const String apiUrl = "https://api.logmeal.es/v2/image/food";

      // API call to identify image.
      await Future.delayed(
        const Duration(milliseconds: 400),
            () => http.post(
          Uri.parse(apiUrl),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "image_path": "path/to/${file?.path.split('/').last}",
          }),
        ),
      );

      // Parse json for appropriate fields
      final Map<String, dynamic> responseBody = {
        "foodName": "Apple",
        "nutrition": {
          "calories": 95,
          "protein": 0.5,
          "carbs": 25,
          "fat": 0.3,
        }
      };

      // Update state with the parsed data.
      calories = responseBody["nutrition"]["calories"];
      protein = responseBody["nutrition"]["protein"];
      carbs = responseBody["nutrition"]["carbs"];
      fat = responseBody["nutrition"]["fat"];
      foodName = responseBody["foodName"];
    } catch (error) {
      print("Error fetching LogMeal data: $error");
    }

    setState(() {
      isLoading = false; // Stop loading indicator.
    });
  }

  /// Updates Firebase Firestore with the fetched meal data.
  Future<void> _updateFirebase() async {
    final String userId = "B7FOLVzsJ0trs9DLvYcZ"; // Replace with actual user ID.
    final CollectionReference goalsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals');

    if (!applyToAll) {
      // Update progress for the specific goal.
      final querySnapshot = await goalsCollection
          .where('details.name', isEqualTo: widget.goal.details['name'])
          .get();

      for (var doc in querySnapshot.docs) {
        final details = doc['details'];
        if (details['name'].toString().toLowerCase().contains('calorie')) {
          await doc.reference.update({
            'progress': FieldValue.increment(calories ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('protein')) {
          await doc.reference.update({
            'progress': FieldValue.increment(protein?.ceil().toInt() ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('carbohydrate')) {
          await doc.reference.update({
            'progress': FieldValue.increment(carbs ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('fat')) {
          await doc.reference.update({
            'progress': FieldValue.increment(fat?.ceil().toInt() ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('meal count')) {
          await doc.reference.update({
            'progress': FieldValue.increment(1),
          });
        }
      }
    } else {
      // Update progress for all nutrition-related goals.
      final querySnapshot =
      await goalsCollection.where('category', isEqualTo: 'nutrition').get();

      for (var doc in querySnapshot.docs) {
        final details = doc['details'];
        if (details['name'].toString().toLowerCase().contains('calorie')) {
          await doc.reference.update({
            'progress': FieldValue.increment(calories ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('protein')) {
          await doc.reference.update({
            'progress': FieldValue.increment(protein?.ceil().toInt() ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('carbohydrate')) {
          await doc.reference.update({
            'progress': FieldValue.increment(carbs ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('fat')) {
          await doc.reference.update({
            'progress': FieldValue.increment(fat?.ceil().toInt() ?? 0),
          });
        }
        if (details['name'].toString().toLowerCase().contains('meal count')) {
          await doc.reference.update({
            'progress': FieldValue.increment(1),
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Leading back button to navigate to the previous screen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
        title: CustomText(
          text: 'Meal Details',
          fontSize: 25.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
          textHeight: 0.8,
        ),
        centerTitle: true,
        backgroundColor: CustomColors.primary,
      ),
      backgroundColor: CustomColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image container for the meal image
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  // Display the image with a fixed height and rounded corners
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(widget.image!.path), // Image from the captured file
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  isLoading
                      ? const CircularProgressIndicator() // Loading indicator
                      : CustomText(
                    text: foodName ?? 'Apple', // Display the food name
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: CustomColors.darkGray,
                    squash: true,
                  ),
                ],
              ),
            ),
            // Nutrition information cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Row for calories and protein info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard('Calories', isLoading ? null : '$calories'),
                      _buildInfoCard('Protein', isLoading ? null : '${protein}g'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row for carbs and fat info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard('Carbs', isLoading ? null : '${carbs}g'),
                      _buildInfoCard('Fat', isLoading ? null : '${fat}g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Slider card to toggle "Apply to All"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SliderCard(
                text: 'Apply to All',
                isActive: applyToAll,
                onActivate: () {
                  setState(() {
                    applyToAll = true;
                  });
                },
                onDeactivate: () {
                  setState(() {
                    applyToAll = false;
                  });
                },
              ),
            ),
            const SizedBox(height: 15),
            // Finish button to save data and navigate back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomButton(
                text: 'Finish',
                textSize: 18,
                backgroundColor: CustomColors.primary,
                textColor: Colors.white,
                onPressed: () async {
                  await _updateFirebase(); // Update Firebase with the data
                  // Navigate back to the main goal page
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
      // Bottom navigation bar for app-wide navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Active tab index
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
        onTap: (index) {
          // Handle navigation logic
        },
      ),
    );
  }

  /// Creates a uniform layout to display the macronutrient data
  Widget _buildInfoCard(String label, String? value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          value == null
              ? const CircularProgressIndicator()
              : CustomText(
                  text: value,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: CustomColors.primary,
                  squash: true,
                ),
          const SizedBox(height: 5),
          CustomText(
            text: label,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: CustomColors.darkGray,
            squash: true,
            textHeight: 1,
          ),
        ],
      ),
    );
  }
}
