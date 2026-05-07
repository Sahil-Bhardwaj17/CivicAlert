// lib/ui/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../core/models/report_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/report_service.dart';
import '../../core/utils/app_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _reportService = ReportService();

  CivicUser? _user;
  List<RoadReport> _userReports = [];
  List<CivicUser> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getCurrentUserData();
    if (user != null) {
      final reports = await _reportService.getUserReports(user.uid);
      final leaderboard = await _authService.getLeaderboard();
      if (mounted) {
        setState(() {
          _user = user;
          _userReports = reports;
          _leaderboard = leaderboard;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not logged in'),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _signOut,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 12),
                      Text(_user!.displayName, style: AppTextStyles.h2White),
                      Text(_user!.phoneNumber,
                          style: AppTextStyles.bodyMediumWhite),
                      const SizedBox(height: 8),
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              _user!.levelTitle,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  // Stats row
                  _StatsGrid(user: _user!),
                  const SizedBox(height: 20),

                  // Badges
                  if (_user!.badges.isNotEmpty) ...[
                    Text('Badges', style: AppTextStyles.h3),
                    const SizedBox(height: 10),
                    _BadgesRow(badges: _user!.badges),
                    const SizedBox(height: 20),
                  ],

                  // Volunteer toggle
                  _VolunteerCard(user: _user!, onToggle: (val) async {
                    await _authService.updateUserProfile(
                      uid: _user!.uid,
                      isVolunteer: val,
                    );
                    setState(() {
                      _user = CivicUser(
                        uid: _user!.uid,
                        phoneNumber: _user!.phoneNumber,
                        displayName: _user!.displayName,
                        totalPoints: _user!.totalPoints,
                        totalReports: _user!.totalReports,
                        resolvedReports: _user!.resolvedReports,
                        monthlyPoints: _user!.monthlyPoints,
                        badges: _user!.badges,
                        isVolunteer: val,
                        joinedAt: _user!.joinedAt,
                        lastActiveAt: _user!.lastActiveAt,
                      );
                    });
                  }),
                  const SizedBox(height: 20),

                  // Leaderboard
                  Row(
                    children: [
                      Text('Monthly Leaderboard', style: AppTextStyles.h3),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Top 10',
                            style: AppTextStyles.chip.copyWith(
                                color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _LeaderboardList(
                    leaderboard: _leaderboard,
                    currentUserId: _user!.uid,
                  ),
                  const SizedBox(height: 20),

                  // My Reports
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Reports (${_userReports.length})',
                          style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_userReports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text('No reports yet',
                            style: AppTextStyles.bodyMedium),
                      ),
                    )
                  else
                    ..._userReports.take(5).map((r) => _MiniReportCard(report: r)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final CivicUser user;
  const _StatsGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _StatCell(
          label: 'Total Points',
          value: '${user.totalPoints}',
          icon: Icons.star_rounded,
          color: Colors.amber,
        ),
        _StatCell(
          label: 'Reports Filed',
          value: '${user.totalReports}',
          icon: Icons.flag_rounded,
          color: AppColors.primary,
        ),
        _StatCell(
          label: 'Issues Resolved',
          value: '${user.resolvedReports}',
          icon: Icons.check_circle_rounded,
          color: AppColors.accent,
        ),
        _StatCell(
          label: 'Resolution Rate',
          value: '${user.resolutionRate}%',
          icon: Icons.trending_up_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: AppTextStyles.h3.copyWith(color: color)),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  final List<String> badges;
  const _BadgesRow({required this.badges});

  @override
  Widget build(BuildContext context) {
    final badgeIcons = {
      'first_report': (Icons.emoji_events_rounded, 'First Report', Colors.amber),
      'ten_reports': (Icons.military_tech_rounded, '10 Reports', AppColors.primary),
      'resolved': (Icons.verified_rounded, 'Issue Resolved', AppColors.accent),
    };

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: badges.map((badge) {
          final info = badgeIcons[badge];
          final icon = info?.$1 ?? Icons.star_rounded;
          final label = info?.$2 ?? badge;
          final color = info?.$3 ?? AppColors.primary;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label,
                    style: AppTextStyles.caption.copyWith(color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final CivicUser user;
  final Function(bool) onToggle;
  const _VolunteerCard({required this.user, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (user.isVolunteer ? AppColors.accent : AppColors.textHint)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: user.isVolunteer ? AppColors.accent : AppColors.textHint,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disaster Volunteer',
                    style: AppTextStyles.labelLarge),
                Text(
                  user.isVolunteer
                      ? 'You are registered as a volunteer'
                      : 'Help others during emergencies',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: user.isVolunteer,
            onChanged: onToggle,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<CivicUser> leaderboard;
  final String currentUserId;
  const _LeaderboardList({
    required this.leaderboard,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: leaderboard.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final user = entry.value;
          final isMe = user.uid == currentUserId;
          final rankColors = {
            1: Colors.amber,
            2: Colors.grey.shade400,
            3: Colors.brown.shade300,
          };
          final rankColor = rankColors[rank] ?? AppColors.textHint;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity(0.05) : null,
              border: rank < leaderboard.length
                  ? const Border(
                  bottom: BorderSide(color: AppColors.divider))
                  : null,
              borderRadius: rank == leaderboard.length
                  ? const BorderRadius.vertical(bottom: Radius.circular(14))
                  : null,
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 28,
                  child: rank <= 3
                      ? Icon(Icons.emoji_events_rounded,
                      color: rankColor, size: 20)
                      : Text(
                    '#$rank',
                    style: AppTextStyles.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.background,
                    shape: BoxShape.circle,
                    border: isMe
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: isMe ? AppColors.primary : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: Text(
                    isMe ? '${user.displayName} (You)' : user.displayName,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isMe ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Points
                Text(
                  '${user.monthlyPoints} pts',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isMe ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniReportCard extends StatelessWidget {
  final RoadReport report;
  const _MiniReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 44,
            decoration: BoxDecoration(
              color: AppUtils.getSeverityColor(report.severity),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(AppUtils.formatDate(report.createdAt),
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppUtils.getStatusColor(report.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppUtils.getStatusLabel(report.status),
              style: AppTextStyles.chip.copyWith(
                color: AppUtils.getStatusColor(report.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
