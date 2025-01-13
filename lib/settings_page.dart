import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';
import 'widgets/button.dart';
import 'widgets/tap_card.dart';
import 'widgets/text.dart';
import 'widgets/slider_card.dart';

/// Allows the user to view and modify any account-specific data
/// such as name, age, weight, and an option to stay signed in
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = '';
  bool appleHealthSync = true;
  bool keepSignedIn = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Fetches the user's name from Firebase
    _fetchKeepSignedInPreference();
  }

  // Fetches the user's name from Firebase
  Future<void> _fetchUserName() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userName = doc['name'] ?? "User Name";
    });
  }

  // Fetches the "Keep Me Signed In" preference from the app's local cache
  Future<void> _fetchKeepSignedInPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      keepSignedIn = prefs.getBool('skipLogin') ?? false;
    });
  }

  // Updates the user's name in Firebase
  Future<void> _updateUserName(String newName) async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'name': newName});
    setState(() {
      userName = newName;
    });
  }

  // Updates the "Keep Me Signed In" preference in the app's local cache
  Future<void> _updateKeepSignedInPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('skipLogin', value);
    setState(() {
      keepSignedIn = value;
    });
  }

  // Shows a popup dialog that allows the user to edit their name
  void _showEditNamePopup() {
    final TextEditingController nameController =
    TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Set popup background color to white
        contentPadding: const EdgeInsets.all(15.0), // Adjust padding for alignment
        title: Center(
          child: CustomText(
            text: 'Change Name',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CustomColors.darkGray,
            squash: true,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: CustomColors.offWhite, // Text field container color
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              // Stores the name the user inputs
              child: TextField(
                controller: nameController,
                cursorColor: CustomColors.primary,
                textAlign: TextAlign.center, // Center the text
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: CustomColors.darkGray,
                  letterSpacing: -0.7,
                  height: 1.0,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.darkGray,
                    letterSpacing: -0.7,
                    height: 1.0,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center, // Center the action button
        actions: [
          GestureDetector(
            onTap: () {
              // Updates the user's name with the new name
              _updateUserName(nameController.text.trim());
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity, // Make the button take full width
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: CustomColors.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: CustomText(
                  text: 'Done',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  squash: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Name Section
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  CustomText(
                    text: userName,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CustomColors.darkGray,
                    squash: true,
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _showEditNamePopup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: CustomColors.primary,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: CustomText(
                        text: 'Change Name',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        squash: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Apple Health Sync Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SliderCard(
              text: 'Apple Health Sync',
              isActive: appleHealthSync,
              onActivate: () => setState(() {
                appleHealthSync = true;
              }),
              onDeactivate: () => setState(() {
                appleHealthSync = false;
              }),
            ),
          ),

          const SizedBox(height: 15),

          // Keep Me Signed In Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SliderCard(
              text: 'Keep Me Signed In',
              isActive: keepSignedIn,
              onActivate: () => _updateKeepSignedInPreference(true),
              onDeactivate: () => _updateKeepSignedInPreference(false),
            ),
          ),

          const SizedBox(height: 15),

          // Navigation Options
          TapCard(
            text: 'Biometrics',
            imagePath: 'assets/images/biometrics.png',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BiometricsPage()),
              );
            },
            backgroundColor: Colors.white,
            containerColor: CustomColors.primary,
            imageColor: Colors.white,
          ),
          const SizedBox(height: 15),
          TapCard(
            text: 'About the App',
            imagePath: 'assets/images/aboutapp.png',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppPage()),
              );
            },
            backgroundColor: Colors.white,
            containerColor: CustomColors.primary,
            imageColor: Colors.white,
          ),

          const SizedBox(height: 15),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Center(
              child: CustomButton(
                text: 'Log Out',
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                },
                backgroundColor: CustomColors.red,
                textColor: Colors.white,
                textSize: 18,
              ),
            ),
          ),
        ],
      );
  }
}

/// Displays a short description about the app and its purpose
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
          color: Colors.white,
        ),
        title: CustomText(
          text: 'About the App',
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          squash: true,
        ),
        centerTitle: true,
        backgroundColor: CustomColors.primary,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: CustomColors.offWhite,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          padding: EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
          ),
          // Description
          child: Text('data'),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
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
}

/// Allows the user to view and edit their biometric data (height, weight, age, gender)
class BiometricsPage extends StatefulWidget {
  const BiometricsPage({Key? key}) : super(key: key);

  @override
  State<BiometricsPage> createState() => _BiometricsPageState();
}

class _BiometricsPageState extends State<BiometricsPage> {
  // Respective controllers to capture user input for each field
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _fetchBiometricData();

    // Initialize focus nodes for each field
    _focusNodes['height'] = FocusNode();
    _focusNodes['weight'] = FocusNode();
    _focusNodes['age'] = FocusNode();
    _focusNodes['gender'] = FocusNode();
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _focusNodes.values.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }

  // Fetches the user's current biometric data from Firebase
  Future<void> _fetchBiometricData() async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc['biometrics'];

    setState(() {
      _heightController.text = data['height'].toString();
      _weightController.text = data['weight'].toString();
      _ageController.text = data['age'].toString();
      _genderController.text = data['gender'];
    });
  }

  // Updates the Firebase data with the user's new input
  Future<void> _updateBiometricData(String field, dynamic value) async {
    final userId = "B7FOLVzsJ0trs9DLvYcZ";
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'biometrics.$field': value,
    });
  }

  // Check if the user's input is valid according to its field
  void _submitField(String field, String value, {bool isText = false}) {
    final newValue = isText ? value : int.tryParse(value);
    if (newValue != null) {
      _updateBiometricData(field, newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and call onSubmitted for active field
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          final field = _focusNodes.entries
              .firstWhere((entry) => entry.value.hasFocus)
              .key;
          switch (field) {
            case 'height':
              _submitField('height', _heightController.text);
              break;
            case 'weight':
              _submitField('weight', _weightController.text);
              break;
            case 'age':
              _submitField('age', _ageController.text);
              break;
            case 'gender':
              _submitField('gender', _genderController.text, isText: true);
              break;
          }
                  currentFocus.unfocus(); // Retract the keyboard
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
          title: CustomText(
            text: 'Biometrics',
            fontSize: 25.0,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            squash: true,
            textHeight: 0.8,
          ),
          centerTitle: true,
          backgroundColor: CustomColors.primary,
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: CustomColors.offWhite,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 15.0),
                _buildBiometricCard('Height', _heightController, 'cm.', 'height'),
                const SizedBox(height: 15.0),
                _buildBiometricCard('Weight', _weightController, 'lbs.', 'weight'),
                const SizedBox(height: 15.0),
                _buildBiometricCard('Age', _ageController, 'yrs.', 'age'),
                const SizedBox(height: 15.0),
                _buildBiometricCard('Gender', _genderController, '', 'gender', isText: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Provides a uniform display the editable fields
  Widget _buildBiometricCard(String label, TextEditingController controller, String unit, String field,
      {bool isText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
      ),
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              text: label,
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: CustomColors.darkGray,
              squash: true,
            ),
          ),
          const SizedBox(width: 80.0),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors.primaryFaded,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: TextField(
                controller: controller,
                focusNode: _focusNodes[field], // Assign the focus node
                cursorColor: CustomColors.primary,
                textAlign: TextAlign.center,
                keyboardType: isText ? TextInputType.text : TextInputType.number,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: CustomColors.darkGray,
                  letterSpacing: -0.7,
                  height: 0.95,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                ),
                onSubmitted: (value) {
                  // Initiate the Firestore update
                  _submitField(field, value, isText: isText);
                },
              ),
            ),
          ),
          if (unit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: CustomText(
                text: unit,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CustomColors.darkGray,
                squash: true,
              ),
            ),
        ],
      ),
    );
  }
}
