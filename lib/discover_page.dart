import 'widgets/activity_of_the_day.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'widgets/weather_card.dart'; // Import your WeatherCard widget
import 'widgets/day_tips.dart';
import 'widgets/tap_card.dart';
import 'widgets/sage.dart';


import 'globals.dart' as globals;

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColors.offWhite,
      child: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const WeatherCard(), // Your WeatherCard widget
                  const SizedBox(height: 15),
                  globals.newDay
                      ? ActivityOfTheDay(
                    videoLink: "https://www.youtube.com/watch?v=dj03_VDetdw", // Indoor Cardio
                    articleLink:
                    "https://health.clevelandclinic.org/the-many-benefits-of-a-cardio-workout",
                  )
                      : ActivityOfTheDay(
                    videoLink: "https://www.youtube.com/watch?v=1xRX1MuoImw", // Surya Namaskaralu
                    articleLink:
                    "https://www.artofliving.org/in-en/yoga/beginners/sun-salutation-benefits",
                  ),
                  SizedBox(height: 15),
                  DayTips(sunny: false),
                  SizedBox(height: 15),
                  TapCard(
                    text: 'Have Any Questions?',
                    subText: 'Ask Sage!',
                    imagePath: 'assets/images/sage.png',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SagePage()),
                      );
                    },
                    backgroundColor: Colors.white,
                    containerColor: CustomColors.turquoise,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
