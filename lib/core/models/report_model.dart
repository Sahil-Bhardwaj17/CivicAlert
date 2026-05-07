// lib/core/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, inProgress, resolved, rejected }
enum SeverityLevel { low, medium, high, critical }
enum ReportCategory { pothole, brokenRoad, waterlogging, streetLight, other }

class RoadReport {
  final String id;
  final String userId;
  final String userPhone;
  final String title;
  final String description;
  final ReportCategory category;
  final SeverityLevel severity;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> imageUrls;
  final ReportStatus status;
  final int upvotes;
  final List<String> upvotedBy;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? municipalNotes;
  final int pointsAwarded;
  final bool isOfflineQueued;

  RoadReport({
    required this.id,
    required this.userId,
    required this.userPhone,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrls,
    this.status = ReportStatus.pending,
    this.upvotes = 0,
    this.upvotedBy = const [],
    required this.createdAt,
    this.resolvedAt,
    this.municipalNotes,
    this.pointsAwarded = 10,
    this.isOfflineQueued = false,
  });

  factory RoadReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoadReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      userPhone: data['userPhone'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: ReportCategory.values.firstWhere(
            (e) => e.name == data['category'],
        orElse: () => ReportCategory.pothole,
      ),
      severity: SeverityLevel.values.firstWhere(
            (e) => e.name == data['severity'],
        orElse: () => SeverityLevel.medium,
      ),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: ReportStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      upvotes: data['upvotes'] ?? 0,
      upvotedBy: List<String>.from(data['upvotedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      municipalNotes: data['municipalNotes'],
      pointsAwarded: data['pointsAwarded'] ?? 10,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userPhone': userPhone,
    'title': title,
    'description': description,
    'category': category.name,
    'severity': severity.name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'imageUrls': imageUrls,
    'status': status.name,
    'upvotes': upvotes,
    'upvotedBy': upvotedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'municipalNotes': municipalNotes,
    'pointsAwarded': pointsAwarded,
  };

  RoadReport copyWith({
    ReportStatus? status,
    int? upvotes,
    List<String>? upvotedBy,
    SeverityLevel? severity,
    String? municipalNotes,
    DateTime? resolvedAt,
  }) {
    return RoadReport(
      id: id,
      userId: userId,
      userPhone: userPhone,
      title: title,
      description: description,
      category: category,
      severity: severity ?? this.severity,
      latitude: latitude,
      longitude: longitude,
      address: address,
      imageUrls: imageUrls,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      municipalNotes: municipalNotes ?? this.municipalNotes,
      pointsAwarded: pointsAwarded,
    );
  }
}