import 'package:health/health.dart';

/// A service class for interacting with health data on the user's device.
class HealthService {
  final Health _health = Health(); // Instance of the Health plugin

  /// Requests authorization to access the specified health data types.
  ///
  /// Returns `true` if authorization is granted, otherwise `false`.
  Future<bool> requestAuthorization() async {
    var types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ];

    try {
      return await _health.requestAuthorization(types);
    } catch (e) {
      print('Error requesting authorization: $e');
      return false;
    }
  }

  /// Fetches health data points for the past 24 hours.
  ///
  /// Returns a list of [HealthDataPoint] objects, or an empty list if an error occurs.
  Future<List<HealthDataPoint>> fetchHealthDataPoints() async {
    var types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ];
    var now = DateTime.now();
    var yesterday = now.subtract(const Duration(days: 1));

    try {
      return await Health().getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
        recordingMethodsToFilter: [
          RecordingMethod.manual,
          RecordingMethod.automatic,
        ],
      );
    } catch (e) {
      print('Error fetching health data points: $e');
      return [];
    }
  }

  /// Requests read permissions for the specified health data types.
  ///
  /// Returns `true` if permissions are granted, otherwise `false`.
  Future<bool> requestReadPermissions() async {
    var types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ];
    var permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    try {
      return await _health.requestAuthorization(types,
          permissions: permissions);
    } catch (e) {
      print('Error requesting read permissions: $e');
      return false;
    }
  }

  /// Fetches the total steps recorded for today.
  ///
  /// Returns the total number of steps as an [int], or `null` if an error occurs.
  Future<int?> fetchTotalStepsToday() async {
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day);

    try {
      return await _health.getTotalStepsInInterval(midnight, now);
    } catch (e) {
      print('Error fetching total steps: $e');
      return null;
    }
  }

  /// Fetches the total active calories burned for today.
  ///
  /// Returns the total calories burned as an [int], or `null` if an error occurs.
  Future<int?> fetchActiveCaloriesToday() async {
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day);

    try {
      // Fetch the active calories burned data
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );

      // Sum up the active calories burned for today
      double totalCalories = 0;
      for (var dataPoint in healthData) {
        if (dataPoint.value is NumericHealthValue) {
          totalCalories += (dataPoint.value as NumericHealthValue).numericValue;
        }
      }

      return totalCalories.toInt(); // Return as an integer
    } catch (e) {
      print('Error fetching active calories: $e');
      return null;
    }
  }

  /// Fetches the total distance walked or run for today.
  ///
  /// Returns the total distance in meters as a [double], or `null` if an error occurs.
  Future<double?> fetchDistanceToday() async {
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day);

    try {
      // Fetch distance walked or run for today
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: midnight,
        endTime: now,
      );

      // Sum up the distance
      double totalDistance = 0;
      for (var dataPoint in healthData) {
        if (dataPoint.value is NumericHealthValue) {
          totalDistance += (dataPoint.value as NumericHealthValue).numericValue;
        }
      }

      return totalDistance;
    } catch (e) {
      print('Error fetching distance: $e');
      return null;
    }
  }
}
