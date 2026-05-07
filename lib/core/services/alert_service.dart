// lib/core/services/alert_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get active alerts stream
  Stream<List<DisasterAlert>> getActiveAlertsStream() {
    return _firestore
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => DisasterAlert.fromFirestore(doc)).toList());
  }

  // Get alerts near location
  Future<List<DisasterAlert>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusDegrees = 0.5,
  }) async {
    final snapshot = await _firestore
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .where('latitude', isGreaterThan: latitude - radiusDegrees)
        .where('latitude', isLessThan: latitude + radiusDegrees)
        .get();

    return snapshot.docs
        .map((doc) => DisasterAlert.fromFirestore(doc))
        .where((alert) =>
    alert.longitude > longitude - radiusDegrees &&
        alert.longitude < longitude + radiusDegrees)
        .toList();
  }

  // Check if location is in alert zone
  Future<List<DisasterAlert>> checkUserInAlertZone(
      double userLat, double userLng,
      ) async {
    final alerts = await getNearbyAlerts(
      latitude: userLat,
      longitude: userLng,
    );

    // Filter alerts where user is within radius
    return alerts.where((alert) {
      final distance = _calculateDistance(
        userLat, userLng, alert.latitude, alert.longitude,
      );
      return distance <= alert.radiusKm * 1000;
    }).toList();
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Simplified distance calculation (use geolocator for production)
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * (3.14159 / 180);
    final dLng = (lng2 - lng1) * (3.14159 / 180);
    final a = dLat * dLat + dLng * dLng;
    return earthRadius * a;
  }

  // Create mock/demo alert (for testing)
  Future<void> createDemoAlert() async {
    final alert = {
      'type': 'flood',
      'severity': 'warning',
      'title': 'Heavy Rainfall Alert - Flood Risk',
      'description': 'Heavy rainfall expected in the next 6 hours. Low-lying areas may experience flooding. Citizens are advised to avoid waterlogged roads.',
      'latitude': 30.9095,
      'longitude': 75.8573,
      'radiusKm': 15.0,
      'affectedAreas': ['Ludhiana City', 'Sahnewal', 'Doraha'],
      'safeZones': [
        {
          'name': 'Government Hospital Ludhiana',
          'latitude': 30.9000,
          'longitude': 75.8600,
          'type': 'hospital',
          'contactNumber': '0161-1234567',
          'capacity': 500,
        },
        {
          'name': 'Civil Lines Community Center',
          'latitude': 30.9150,
          'longitude': 75.8500,
          'type': 'shelter',
          'capacity': 200,
        }
      ],
      'evacuationRoutes': [],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'OpenWeatherMap + Gemini AI',
      'weatherData': {
        'rainfall': '45mm/hr',
        'windSpeed': '35km/h',
        'humidity': '95%',
      },
    };
    await _firestore.collection('alerts').add(alert);
  }
}