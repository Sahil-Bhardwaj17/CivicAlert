// lib/core/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CivicUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String? photoUrl;
  final String? email;
  final int totalPoints;
  final int totalReports;
  final int resolvedReports;
  final int monthlyPoints;
  final int leaderboardRank;
  final List<String> badges;
  final bool isVolunteer;
  final String preferredLanguage;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? homeArea;
  final DateTime joinedAt;
  final DateTime lastActiveAt;

  CivicUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    this.photoUrl,
    this.email,
    this.totalPoints = 0,
    this.totalReports = 0,
    this.resolvedReports = 0,
    this.monthlyPoints = 0,
    this.leaderboardRank = 0,
    this.badges = const [],
    this.isVolunteer = false,
    this.preferredLanguage = 'en',
    this.homeLatitude,
    this.homeLongitude,
    this.homeArea,
    required this.joinedAt,
    required this.lastActiveAt,
  });

  factory CivicUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CivicUser(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      displayName: data['displayName'] ?? 'Civic Citizen',
      photoUrl: data['photoUrl'],
      email: data['email'],
      totalPoints: data['totalPoints'] ?? 0,
      totalReports: data['totalReports'] ?? 0,
      resolvedReports: data['resolvedReports'] ?? 0,
      monthlyPoints: data['monthlyPoints'] ?? 0,
      leaderboardRank: data['leaderboardRank'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      isVolunteer: data['isVolunteer'] ?? false,
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      homeLatitude: data['homeLatitude']?.toDouble(),
      homeLongitude: data['homeLongitude']?.toDouble(),
      homeArea: data['homeArea'],
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'phoneNumber': phoneNumber,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'email': email,
    'totalPoints': totalPoints,
    'totalReports': totalReports,
    'resolvedReports': resolvedReports,
    'monthlyPoints': monthlyPoints,
    'leaderboardRank': leaderboardRank,
    'badges': badges,
    'isVolunteer': isVolunteer,
    'preferredLanguage': preferredLanguage,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'homeArea': homeArea,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'lastActiveAt': Timestamp.fromDate(lastActiveAt),
  };

  String get levelTitle {
    if (totalPoints < 100) return 'Newcomer';
    if (totalPoints < 500) return 'Civic Scout';
    if (totalPoints < 1000) return 'Road Warrior';
    if (totalPoints < 2500) return 'Community Hero';
    if (totalPoints < 5000) return 'City Guardian';
    return 'Civic Champion';
  }

  int get resolutionRate =>
      totalReports > 0 ? ((resolvedReports / totalReports) * 100).round() : 0;
}