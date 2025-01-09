import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  // Request authorization for the required data types
  Future<bool> requestAuthorization() async {
    var types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING
    ];

    try {
      return await _health.requestAuthorization(types);
    } catch (e) {
      print('Error requesting authorization: $e');
      return false;
    }
  }

  // Fetch health data points for the last 24 hours
  Future<List<HealthDataPoint>> fetchHealthDataPoints() async {
    var types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ];
    var now = DateTime.now();
    var yesterday = now.subtract(Duration(days: 1));

    try {
      return await Health().getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
        recordingMethodsToFilter: [
          RecordingMethod.manual,
          RecordingMethod.automatic
        ],
      );
    } catch (e) {
      print('Error fetching health data points: $e');
      return [];
    }
  }

  // Request permissions to write health data
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
      print('Error requesting write permissions: $e');
      return false;
    }
  }

  // Fetch total steps for today
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
