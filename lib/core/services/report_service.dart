// lib/core/services/report_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create new report
  Future<String> createReport(RoadReport report, List<File> imageFiles) async {
    final docRef = _firestore.collection('reports').doc();

    // Upload images
    final imageUrls = <String>[];
    for (int i = 0; i < imageFiles.length; i++) {
      final ref = _storage.ref('reports/${docRef.id}/image_$i.jpg');
      await ref.putFile(imageFiles[i]);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    final updatedReport = RoadReport(
      id: docRef.id,
      userId: report.userId,
      userPhone: report.userPhone,
      title: report.title,
      description: report.description,
      category: report.category,
      severity: report.severity,
      latitude: report.latitude,
      longitude: report.longitude,
      address: report.address,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    await docRef.set(updatedReport.toFirestore());
    return docRef.id;
  }

  // Get reports stream
  Stream<List<RoadReport>> getReportsStream({
    ReportStatus? status,
    SeverityLevel? severity,
    String? userId,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true);

    if (status != null) query = query.where('status', isEqualTo: status.name);
    if (severity != null) query = query.where('severity', isEqualTo: severity.name);
    if (userId != null) query = query.where('userId', isEqualTo: userId);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => RoadReport.fromFirestore(doc))
          .toList(),
    );
  }

  // Get nearby reports
  Future<List<RoadReport>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusDegrees = 0.05, // ~5km
  }) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('latitude', isGreaterThan: latitude - radiusDegrees)
        .where('latitude', isLessThan: latitude + radiusDegrees)
        .get();

    return snapshot.docs
        .map((doc) => RoadReport.fromFirestore(doc))
        .where((report) =>
    report.longitude > longitude - radiusDegrees &&
        report.longitude < longitude + radiusDegrees)
        .toList();
  }

  // Get single report
  Future<RoadReport?> getReport(String reportId) async {
    final doc = await _firestore.collection('reports').doc(reportId).get();
    if (!doc.exists) return null;
    return RoadReport.fromFirestore(doc);
  }

  // Upvote report
  Future<void> toggleUpvote(String reportId, String userId) async {
    final docRef = _firestore.collection('reports').doc(reportId);
    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>;
    final upvotedBy = List<String>.from(data['upvotedBy'] ?? []);

    if (upvotedBy.contains(userId)) {
      await docRef.update({
        'upvotes': FieldValue.increment(-1),
        'upvotedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'upvotes': FieldValue.increment(1),
        'upvotedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // Update report status
  Future<void> updateReportStatus(
      String reportId,
      ReportStatus status, {
        String? notes,
      }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      if (notes != null) 'municipalNotes': notes,
      if (status == ReportStatus.resolved)
        'resolvedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('reports').doc(reportId).update(updates);
  }

  // Get user reports
  Future<List<RoadReport>> getUserReports(String userId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => RoadReport.fromFirestore(doc)).toList();
  }

  // Delete report
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection('reports').doc(reportId).delete();
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    final snapshot = await _firestore.collection('reports').get();
    final reports = snapshot.docs.map((doc) => RoadReport.fromFirestore(doc)).toList();

    return {
      'total': reports.length,
      'pending': reports.where((r) => r.status == ReportStatus.pending).length,
      'inProgress': reports.where((r) => r.status == ReportStatus.inProgress).length,
      'resolved': reports.where((r) => r.status == ReportStatus.resolved).length,
      'critical': reports.where((r) => r.severity == SeverityLevel.critical).length,
    };
  }
}