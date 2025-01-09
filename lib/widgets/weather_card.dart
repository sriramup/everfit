import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import '../colors.dart'; // Your custom colors
import '../widgets/text.dart'; // CustomText widget

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final String apiKey = 'd57015f4ae46e18d7ec240206e240adc'; // Your API key
  late WeatherFactory weatherFactory;
  Weather? weatherData;
  String? location = 'Fetching location...';
  String? weatherMessage = 'Fetching weather...';
  String iconPath = 'assets/images/sunny.png'; // Default weather icon

  @override
  void initState() {
    super.initState();
    weatherFactory = WeatherFactory(apiKey);
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      // Get weather for current location
      Weather weather = await weatherFactory.currentWeatherByCityName(
          'Plano'); // Replace "Plano" with dynamic location if needed

      // Determine weather message and icon based on temperature
      final temp = weather.temperature?.fahrenheit ?? 0.0;
      String message;
      if (temp <= 40) {
        message = "Better exercise indoors today!";
        iconPath =
            'assets/images/snowflake.png'; // Add an icon for cold weather
      } else if (temp <= 60) {
        message = "Don't stay outside for too long!";
        iconPath = 'assets/images/cloudy.png'; // Add an icon for cool weather
      } else {
        message = "Seems like a great day to go running!";
        iconPath = 'assets/images/sunny.png'; // Add an icon for warm weather
      }

      setState(() {
        weatherData = weather;
        location = 'Plano, TX.';
        weatherMessage = message;
      });
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blue background section
          Container(
            decoration: BoxDecoration(
              color: CustomColors.skyBlue,
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            ),
            padding: const EdgeInsets.only(
                left: 15.0, right: 15.0, top: 25, bottom: 25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Weather icon
                Image.asset(
                  iconPath,
                  width: 70.0,
                  height: 70.0,
                ),
                const SizedBox(width: 15.0),
                // Temperature, location, and sky condition
                Expanded(
                  // Use Expanded to ensure content fits within the Row
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            text: weatherData?.temperature?.celsius != null
                                ? '${weatherData!.temperature!.fahrenheit!.toStringAsFixed(0)}°F'
                                : '--°F',
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            squash: true,
                          ),
                          const SizedBox(width: 25.0), // Adjusted spacing
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: weatherData?.weatherMain ?? 'N/A',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  squash: true,
                                  textHeight: 0.8,
                                ),
                                CustomText(
                                  text: location ?? '',
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  squash: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom text section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CustomText(
              text: weatherMessage ?? '',
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: CustomColors.gray,
              squash: true,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
