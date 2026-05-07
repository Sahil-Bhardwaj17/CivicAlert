// lib/core/models/alert_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { flood, storm, earthquake, fire, heatwave, cyclone, other }
enum AlertSeverity { advisory, watch, warning, emergency }

class DisasterAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<String> affectedAreas;
  final List<SafeZone> safeZones;
  final List<EvacuationRoute> evacuationRoutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String source;
  final Map<String, dynamic>? weatherData;

  DisasterAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.affectedAreas,
    required this.safeZones,
    required this.evacuationRoutes,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
    required this.source,
    this.weatherData,
  });

  factory DisasterAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisasterAlert(
      id: doc.id,
      type: AlertType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => AlertType.other,
      ),
      severity: AlertSeverity.values.firstWhere(
            (e) => e.name == data['severity'],
        orElse: () => AlertSeverity.advisory,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      radiusKm: (data['radiusKm'] ?? 10.0).toDouble(),
      affectedAreas: List<String>.from(data['affectedAreas'] ?? []),
      safeZones: (data['safeZones'] as List<dynamic>? ?? [])
          .map((e) => SafeZone.fromMap(e as Map<String, dynamic>))
          .toList(),
      evacuationRoutes: (data['evacuationRoutes'] as List<dynamic>? ?? [])
          .map((e) => EvacuationRoute.fromMap(e as Map<String, dynamic>))
          .toList(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      source: data['source'] ?? 'CivicAlert AI',
      weatherData: data['weatherData'],
    );
  }

  String get typeLabel {
    switch (type) {
      case AlertType.flood: return 'Flood';
      case AlertType.storm: return 'Storm';
      case AlertType.earthquake: return 'Earthquake';
      case AlertType.fire: return 'Fire';
      case AlertType.heatwave: return 'Heatwave';
      case AlertType.cyclone: return 'Cyclone';
      case AlertType.other: return 'Alert';
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.advisory: return 'Advisory';
      case AlertSeverity.watch: return 'Watch';
      case AlertSeverity.warning: return 'Warning';
      case AlertSeverity.emergency: return 'Emergency';
    }
  }
}

class SafeZone {
  final String name;
  final double latitude;
  final double longitude;
  final String type; // hospital, shelter, school
  final String? contactNumber;
  final int? capacity;

  SafeZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.contactNumber,
    this.capacity,
  });

  factory SafeZone.fromMap(Map<String, dynamic> map) => SafeZone(
    name: map['name'] ?? '',
    latitude: (map['latitude'] ?? 0.0).toDouble(),
    longitude: (map['longitude'] ?? 0.0).toDouble(),
    type: map['type'] ?? 'shelter',
    contactNumber: map['contactNumber'],
    capacity: map['capacity'],
  );
}

class EvacuationRoute {
  final String name;
  final String description;
  final List<Map<String, double>> waypoints;
  final bool isOpen;

  EvacuationRoute({
    required this.name,
    required this.description,
    required this.waypoints,
    required this.isOpen,
  });

  factory EvacuationRoute.fromMap(Map<String, dynamic> map) => EvacuationRoute(
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    waypoints: (map['waypoints'] as List<dynamic>? ?? [])
        .map((e) => Map<String, double>.from(e as Map))
        .toList(),
    isOpen: map['isOpen'] ?? true,
  );
}