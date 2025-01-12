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

class ScanMealPage extends StatefulWidget {
  final GoalProgress goal;
  final List<CameraDescription> cameras;

  const ScanMealPage({super.key, required this.goal, required this.cameras});

  @override
  State<ScanMealPage> createState() => _ScanMealPageState();
}

class _ScanMealPageState extends State<ScanMealPage> {
  late CameraController _cameraController;
  XFile? capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraController =
          CameraController(widget.cameras[0], ResolutionPreset.high);
      await _cameraController.initialize();
      print('done');
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

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
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fixedHeight = MediaQuery.of(context).size.height *
        0.7; // Fixed height for the camera view
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        // Increase height of the AppBar
        child: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }, // Custom back button behavior
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            capturedImage != null
                ? SizedBox(
                    width: screenWidth,
                    height: fixedHeight,
                    child: Image.file(
                      File(capturedImage!.path), // Load the captured image
                      fit: BoxFit
                          .fitWidth, // Maintain aspect ratio and chop off excess
                    ),
                  )
                : ClipRect(
                    child: SizedBox(
                      width: screenWidth,
                      height: fixedHeight,
                      child: FittedBox(
                        fit: BoxFit.fitWidth, // Do not scale the camera preview
                        child: SizedBox(
                          width: screenWidth,
                          child: CameraPreview(_cameraController),
                        ),
                      ),
                    ),
                  ),
            // Bottom black container with buttons
            Container(
              color: Colors.black,
              width: screenWidth,
              height: MediaQuery.of(context).size.height -
                  fixedHeight -
                  130, // Remaining height
              child: Center(
                child: capturedImage == null
                    ? SizedBox(
                        width: 80,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: _captureImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0, // No elevation
                            shape: const CircleBorder(), // Circular button
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
                          // Retake Button
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                capturedImage = null; // Reset to camera mode
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0, // No elevation
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
                          // Done Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MealDetailsPage(
                                      goal: widget.goal, image: capturedImage),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomColors.primary,
                              elevation: 0, // No elevation
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

class MealDetailsPage extends StatefulWidget {
  final GoalProgress goal;
  final XFile? image;

  const MealDetailsPage({super.key, required this.goal, this.image});

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  bool applyToAll = false;
  int? calories;
  double? protein;
  int? carbs;
  double? fat;
  String? foodName;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogMealData(widget.image);
  }

  Future<void> _fetchLogMealData(XFile? file) async {
    setState(() {
      isLoading = true;
    });

    try {
      // LogMeal API Key
      const String apiKey = "wjhlidhopd13409";
      const String apiUrl = "https://api.logmeal.es/v2/image/food";

      // Sending a POST request with the image
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

      // Parse response
      final Map<String, dynamic> responseBody = {
        "foodName": "Apple",
        "nutrition": {
          "calories": 95,
          "protein": 0.5,
          "carbs": 25,
          "fat": 0.3,
        }
      };

      // Update the state with parsed data
      calories = responseBody["nutrition"]["calories"];
      protein = responseBody["nutrition"]["protein"];
      carbs = responseBody["nutrition"]["carbs"];
      fat = responseBody["nutrition"]["fat"];
      foodName = responseBody["foodName"];
    } catch (error) {
      print("Error fetching LogMeal data: $error");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateFirebase() async {
    final String userId = "B7FOLVzsJ0trs9DLvYcZ";
    final CollectionReference goalsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals');

    if (!applyToAll) {
      // Update the specific goal
      final querySnapshot = await goalsCollection
          .where('details.name', isEqualTo: widget.goal.details['name'])
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'progress': FieldValue.increment(calories ?? 0),
        });
      }
    } else {
      // Update all nutrition goals
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            // Image container
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(widget.image!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  isLoading
                      ? const CircularProgressIndicator()
                      : CustomText(
                          text: foodName ?? 'Apple',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: CustomColors.darkGray,
                          squash: true,
                        ),
                ],
              ),
            ),
            // Nutrition info cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard(
                          'Calories', isLoading ? null : '$calories'),
                      _buildInfoCard(
                          'Protein', isLoading ? null : '${protein}g'),
                    ],
                  ),
                  const SizedBox(height: 10),
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
            // Apply to All slider
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
            // Finish button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomButton(
                text: 'Finish',
                textSize: 18,
                backgroundColor: CustomColors.primary,
                textColor: Colors.white,
                onPressed: () async {
                  await _updateFirebase();
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          // Navigation logic
        },
      ),
    );
  }

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
