import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import '../colors.dart'; // Your custom colors
import '../widgets/text.dart'; // CustomText widget

/// A widget that displays the current weather information, including temperature,
/// location, and a weather-related message based on the fetched weather data.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  // OpenWeatherMap API key for fetching weather data
  final String apiKey = 'd57015f4ae46e18d7ec240206e240adc';

  // WeatherFactory instance to interact with the weather API
  late WeatherFactory weatherFactory;

  // Variables to store fetched weather data and related information
  Weather? weatherData; // Stores the fetched weather information
  String? location = 'Fetching location...'; // Location name to display
  String? weatherMessage = 'Fetching weather...'; // Message based on weather conditions
  String iconPath = 'assets/images/sunny.png'; // Default icon path for sunny weather

  @override
  void initState() {
    super.initState();
    weatherFactory = WeatherFactory(apiKey); // Initialize the weather API instance
    _fetchWeatherData(); // Fetch weather data when the widget is initialized
  }

  /// Fetches the current weather data for a predefined location ("Plano").
  /// Updates the state variables with the fetched data to reflect in the UI.
  Future<void> _fetchWeatherData() async {
    try {
      // Fetch weather data for the specified city
      Weather weather = await weatherFactory.currentWeatherByCityName('Plano');

      // Extract temperature and determine the weather message and icon
      final temp = weather.temperature?.fahrenheit ?? 0.0;
      String message;
      if (temp <= 40) {
        message = "Better exercise indoors today!";
        iconPath = 'assets/images/snowflake.png'; // Icon for cold weather
      } else if (temp <= 60) {
        message = "Don't stay outside for too long!";
        iconPath = 'assets/images/cloudy.png'; // Icon for cool weather
      } else {
        message = "Seems like a great day to go running!";
        iconPath = 'assets/images/sunny.png'; // Icon for warm weather
      }

      // Update state with fetched data and computed values
      setState(() {
        weatherData = weather;
        location = 'Plano, TX.'; // Display location
        weatherMessage = message; // Display the weather message
      });
    } catch (e) {
      // Handle and log any errors during API fetch
      print('Error fetching weather: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0), // Rounded corners for the card
        color: Colors.white, // White background for the card
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section with a blue background for displaying weather details
          Container(
            decoration: BoxDecoration(
              color: CustomColors.skyBlue, // Custom blue background color
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Weather icon
                Image.asset(
                  iconPath, // Display weather icon based on conditions
                  width: 70.0,
                  height: 70.0,
                ),
                const SizedBox(width: 15.0), // Spacing between icon and text
                // Weather details: temperature, condition, and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Display the temperature in Fahrenheit
                          CustomText(
                            text: weatherData?.temperature?.fahrenheit != null
                                ? '${weatherData!.temperature!.fahrenheit!.toStringAsFixed(0)}°F'
                                : '--°F', // Fallback text if temperature is unavailable
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text for contrast
                            squash: true,
                          ),
                          const SizedBox(width: 25.0), // Spacing between temperature and details
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display the weather condition (e.g., Clear, Cloudy)
                                CustomText(
                                  text: weatherData?.weatherMain ?? 'N/A',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  squash: true,
                                  textHeight: 0.8,
                                ),
                                // Display the location (e.g., Plano, TX)
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
          // Bottom section with a weather-related message
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CustomText(
              text: weatherMessage ?? '', // Display the weather message
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: CustomColors.gray, // Gray text color for better readability
              squash: true,
              textAlign: TextAlign.center, // Center-align the message
            ),
          ),
        ],
      ),
    );
  }
}
