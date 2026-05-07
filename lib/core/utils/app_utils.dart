// lib/core/utils/app_utils.dart
import 'package:civicalert/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import '../models/alert_model.dart';

class AppUtils {
  AppUtils._();

  // Format date
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(date);
  }

  // Severity
  static Color getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low: return AppColors.severityLow;
      case SeverityLevel.medium: return AppColors.severityMedium;
      case SeverityLevel.high: return AppColors.severityHigh;
      case SeverityLevel.critical: return AppColors.severityCritical;
    }
  }

  static String getSeverityLabel(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low: return 'Low';
      case SeverityLevel.medium: return 'Medium';
      case SeverityLevel.high: return 'High';
      case SeverityLevel.critical: return 'Critical';
    }
  }

  // Status
  static Color getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending: return AppColors.statusPending;
      case ReportStatus.inProgress: return AppColors.statusInProgress;
      case ReportStatus.resolved: return AppColors.statusResolved;
      case ReportStatus.rejected: return AppColors.statusRejected;
    }
  }

  static String getStatusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending: return 'Pending';
      case ReportStatus.inProgress: return 'In Progress';
      case ReportStatus.resolved: return 'Resolved';
      case ReportStatus.rejected: return 'Rejected';
    }
  }

  static IconData getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending: return Icons.hourglass_empty_rounded;
      case ReportStatus.inProgress: return Icons.engineering_rounded;
      case ReportStatus.resolved: return Icons.check_circle_rounded;
      case ReportStatus.rejected: return Icons.cancel_rounded;
    }
  }

  // Category
  static String getCategoryLabel(ReportCategory category) {
    switch (category) {
      case ReportCategory.pothole: return 'Pothole';
      case ReportCategory.brokenRoad: return 'Broken Road';
      case ReportCategory.waterlogging: return 'Waterlogging';
      case ReportCategory.streetLight: return 'Street Light';
      case ReportCategory.other: return 'Other';
    }
  }

  static IconData getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.pothole: return Icons.radio_button_unchecked;
      case ReportCategory.brokenRoad: return Icons.broken_image_rounded;
      case ReportCategory.waterlogging: return Icons.water_rounded;
      case ReportCategory.streetLight: return Icons.lightbulb_outline_rounded;
      case ReportCategory.other: return Icons.report_problem_rounded;
    }
  }

  // Alert
  static Color getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.flood: return AppColors.alertFlood;
      case AlertType.storm: return AppColors.alertStorm;
      case AlertType.fire: return AppColors.alertFire;
      case AlertType.earthquake: return AppColors.alertEarthquake;
      default: return AppColors.secondary;
    }
  }

  static IconData getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.flood: return Icons.water_damage_rounded;
      case AlertType.storm: return Icons.thunderstorm_rounded;
      case AlertType.fire: return Icons.local_fire_department_rounded;
      case AlertType.earthquake: return Icons.waves_rounded;
      case AlertType.heatwave: return Icons.wb_sunny_rounded;
      case AlertType.cyclone: return Icons.cyclone_rounded;
      case AlertType.other: return Icons.warning_amber_rounded;
    }
  }

  // Show snackbar
  static void showSnackBar(
      BuildContext context,
      String message, {
        bool isError = false,
        bool isSuccess = false,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_rounded
                  : isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppColors.secondary
            : isSuccess
            ? AppColors.accent
            : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Validate phone number
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{10,13}$').hasMatch(phone);
  }

  // Format phone for Firebase
  static String formatPhoneForFirebase(String phone) {
    if (!phone.startsWith('+')) {
      return '+91$phone'; // India default
    }
    return phone;
  }
}