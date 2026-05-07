// lib/core/services/ai_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/report_model.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAXj90eGPT1bUADTyOEHWVRggoFEg0CRWk'; // Replace with actual key
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  // Analyze pothole/road issue image for severity
  Future<SeverityAnalysisResult> analyzeRoadIssue(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final prompt = '''
Analyze this road/infrastructure image and respond ONLY with valid JSON in this exact format:
{
  "severity": "low|medium|high|critical",
  "category": "pothole|brokenRoad|waterlogging|streetLight|other",
  "confidence": 0.85,
  "description": "Brief description of the issue detected",
  "estimatedRisk": "Brief risk assessment for commuters",
  "recommendedAction": "What municipal action is needed"
}

Severity guidelines:
- low: Minor surface damage, cosmetic issues
- medium: Noticeable damage affecting ride quality
- high: Significant damage posing safety risk
- critical: Severe damage causing immediate danger
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '{}';

      // Clean JSON
      final jsonStr = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return SeverityAnalysisResult(
        severity: SeverityLevel.values.firstWhere(
              (e) => e.name == json['severity'],
          orElse: () => SeverityLevel.medium,
        ),
        category: ReportCategory.values.firstWhere(
              (e) => e.name == json['category'],
          orElse: () => ReportCategory.pothole,
        ),
        confidence: (json['confidence'] ?? 0.7).toDouble(),
        description: json['description'] ?? 'Road issue detected',
        estimatedRisk: json['estimatedRisk'] ?? 'Risk assessment unavailable',
        recommendedAction: json['recommendedAction'] ?? 'Municipal inspection required',
      );
    } catch (e) {
      return SeverityAnalysisResult(
        severity: SeverityLevel.medium,
        category: ReportCategory.pothole,
        confidence: 0.0,
        description: 'AI analysis unavailable',
        estimatedRisk: 'Manual assessment needed',
        recommendedAction: 'Submit for manual review',
      );
    }
  }

  // Predict flood risk based on weather data
  Future<FloodRiskResult> predictFloodRisk({
    required double latitude,
    required double longitude,
    required Map<String, dynamic> weatherData,
  }) async {
    try {
      final prompt = '''
Analyze this weather data and predict flood risk for the location.
Location: Lat $latitude, Lng $longitude
Weather Data: ${jsonEncode(weatherData)}

Respond ONLY with valid JSON:
{
  "riskLevel": "low|moderate|high|critical",
  "riskScore": 0.75,
  "floodProbability": 0.65,
  "timeToFlood": "2-4 hours",
  "recommendation": "Action to take",
  "evacuationAdvised": false
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final jsonStr = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return FloodRiskResult(
        riskLevel: json['riskLevel'] ?? 'low',
        riskScore: (json['riskScore'] ?? 0.0).toDouble(),
        floodProbability: (json['floodProbability'] ?? 0.0).toDouble(),
        timeToFlood: json['timeToFlood'] ?? 'Not imminent',
        recommendation: json['recommendation'] ?? 'Monitor conditions',
        evacuationAdvised: json['evacuationAdvised'] ?? false,
      );
    } catch (e) {
      return FloodRiskResult(
        riskLevel: 'unknown',
        riskScore: 0.0,
        floodProbability: 0.0,
        timeToFlood: 'Unknown',
        recommendation: 'Check local authorities',
        evacuationAdvised: false,
      );
    }
  }

  // Generate RTI application text
  Future<String> generateRTIApplication({
    required String reportId,
    required String reportTitle,
    required String reportDate,
    required String reportAddress,
    required String citizenName,
    required String citizenPhone,
  }) async {
    final prompt = '''
Generate a formal RTI (Right to Information) application in India for an unresolved civic road issue.

Report Details:
- Report ID: $reportId
- Issue: $reportTitle
- Location: $reportAddress
- Reported Date: $reportDate
- Citizen: $citizenName
- Contact: $citizenPhone

Write a professional RTI application addressed to the Public Information Officer of the Municipal Corporation.
Include: subject, issue description, information sought, legal basis (RTI Act 2005 Section 6),
and formal closing. Keep it professional and concise.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Unable to generate RTI application. Please contact authorities directly.';
  }
}

class SeverityAnalysisResult {
  final SeverityLevel severity;
  final ReportCategory category;
  final double confidence;
  final String description;
  final String estimatedRisk;
  final String recommendedAction;

  SeverityAnalysisResult({
    required this.severity,
    required this.category,
    required this.confidence,
    required this.description,
    required this.estimatedRisk,
    required this.recommendedAction,
  });
}

class FloodRiskResult {
  final String riskLevel;
  final double riskScore;
  final double floodProbability;
  final String timeToFlood;
  final String recommendation;
  final bool evacuationAdvised;

  FloodRiskResult({
    required this.riskLevel,
    required this.riskScore,
    required this.floodProbability,
    required this.timeToFlood,
    required this.recommendation,
    required this.evacuationAdvised,
  });
}