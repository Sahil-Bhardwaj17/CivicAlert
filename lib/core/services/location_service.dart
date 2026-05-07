// lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

class LocationService {
  static const String _weatherApiKey = 'aebddf2b1d83c78dd0be5f41990a3712';
  static const String _weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  final Dio _dio = Dio();

  // Check and request location permissions
  Future<bool> checkPermissions() async {
    // Check if GPS is on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If denied, request it
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // If permanently denied, open app settings
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }
  // Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  // Convert coordinates to address
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Unknown location';

      final place = placemarks.first;
      final parts = [
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((p) => p != null && p.isNotEmpty).toList();

      return parts.join(', ');
    } catch (e) {
      return 'Location: $lat, $lng';
    }
  }

  // Stream position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(
      double lat1, double lng1, double lat2, double lng2,
      ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Get current weather data
  Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '$_weatherBaseUrl/weather',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'appid': _weatherApiKey,
          'units': 'metric',
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Get weather forecast
  Future<Map<String, dynamic>?> getWeatherForecast(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '$_weatherBaseUrl/forecast',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'appid': _weatherApiKey,
          'units': 'metric',
          'cnt': 24, // 3-day forecast
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}