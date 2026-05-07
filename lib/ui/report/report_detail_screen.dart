// lib/ui/report/report_detail_screen.dart
import 'package:civicalert/core/constants/app_colors.dart';
import 'package:civicalert/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/report_model.dart';
import '../../core/services/report_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/app_utils.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _reportService = ReportService();
  final _aiService = AIService();
  late RoadReport _report;
  bool _hasUpvoted = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report = ModalRoute.of(context)!.settings.arguments as RoadReport;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _hasUpvoted = _report.upvotedBy.contains(uid);
  }

  Future<void> _toggleUpvote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    await _reportService.toggleUpvote(_report.id, uid);
    setState(() {
      if (_hasUpvoted) {
        _hasUpvoted = false;
        _report = _report.copyWith(
          upvotes: _report.upvotes - 1,
          upvotedBy: [..._report.upvotedBy]..remove(uid),
        );
      } else {
        _hasUpvoted = true;
        _report = _report.copyWith(
          upvotes: _report.upvotes + 1,
          upvotedBy: [..._report.upvotedBy, uid],
        );
      }
    });
  }

  Future<void> _generateRTI() async {
    setState(() => _isLoading = true);
    try {
      final rti = await _aiService.generateRTIApplication(
        reportId: _report.id,
        reportTitle: _report.title,
        reportDate: AppUtils.formatFullDate(_report.createdAt),
        reportAddress: _report.address,
        citizenName: 'Citizen',
        citizenPhone: _report.userPhone,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _showRTIDialog(rti);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppUtils.showSnackBar(context, 'Failed to generate RTI', isError: true);
      }
    }
  }

  void _showRTIDialog(String rtiText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('RTI Application', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () => Share.share(rtiText),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(rtiText, style: AppTextStyles.bodyMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severity = _report.severity;
    final status = _report.status;
    final severityColor = AppUtils.getSeverityColor(severity);
    final statusColor = AppUtils.getStatusColor(status);
    final daysSinceReport = DateTime.now().difference(_report.createdAt).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: _report.imageUrls.isNotEmpty ? 240 : 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () => Share.share(
                  'Check this road issue: ${_report.title} at ${_report.address}. Reported on CivicAlert.',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _report.imageUrls.isNotEmpty
                  ? Image.network(
                _report.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary.withOpacity(0.3),
                  child: const Icon(Icons.broken_image_rounded,
                      color: Colors.white54, size: 60),
                ),
              )
                  : Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: const Center(
                  child: Icon(Icons.report_problem_rounded,
                      color: Colors.white54, size: 60),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Severity chips
                  Row(
                    children: [
                      _Chip(
                        label: AppUtils.getStatusLabel(status),
                        color: statusColor,
                        icon: AppUtils.getStatusIcon(status),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: AppUtils.getSeverityLabel(severity),
                        color: severityColor,
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: AppUtils.getCategoryLabel(_report.category),
                        color: AppColors.primary,
                        icon: AppUtils.getCategoryIcon(_report.category),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(_report.title, style: AppTextStyles.h2),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_report.address,
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.textHint, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppUtils.formatFullDate(_report.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 6),
                        Text(_report.description, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Upvotes & actions row
                  Row(
                    children: [
                      _ActionButton(
                        icon: _hasUpvoted
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_alt_outlined,
                        label: '${_report.upvotes} Upvotes',
                        color: _hasUpvoted ? AppColors.primary : AppColors.textSecondary,
                        onTap: _toggleUpvote,
                      ),
                      const SizedBox(width: 10),
                      _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        color: AppColors.textSecondary,
                        onTap: () => Share.share(
                          'Road issue: ${_report.title} at ${_report.address}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Image gallery
                  if (_report.imageUrls.length > 1) ...[
                    Text('Photos (${_report.imageUrls.length})',
                        style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _report.imageUrls.length,
                        itemBuilder: (_, i) => Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(_report.imageUrls[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Municipal notes
                  if (_report.municipalNotes != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusInProgress.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.statusInProgress.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.engineering_rounded,
                                  color: AppColors.statusInProgress, size: 16),
                              const SizedBox(width: 6),
                              Text('Municipal Response',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.statusInProgress,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_report.municipalNotes!,
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Escalation section
                  if (daysSinceReport >= 7 && _report.status == ReportStatus.pending) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.secondary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '$daysSinceReport days unresolved',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            daysSinceReport >= 30
                                ? 'This issue has been unresolved for over 30 days. Generate an RTI application.'
                                : 'This issue has been pending for over 7 days. Consider escalating via social media.',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          if (daysSinceReport >= 30)
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generateRTI,
                              icon: const Icon(Icons.gavel_rounded, size: 16),
                              label: _isLoading
                                  ? const Text('Generating...')
                                  : const Text('Generate RTI Application'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => Share.share(
                                '🚨 ${daysSinceReport} days and no action! Report ID: ${_report.id}\n\n${_report.title}\nAt: ${_report.address}\n\n#CivicAlert #RoadSafety',
                              ),
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: const Text('Escalate on Social Media'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.chip.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.labelMedium.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}