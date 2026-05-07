// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/report_model.dart';
import '../../core/models/alert_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/report_service.dart';
import '../../core/services/alert_service.dart';
import '../../core/utils/app_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _reportService = ReportService();
  final _alertService = AlertService();
  final _authService = AuthService();
  CivicUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) setState(() => _currentUser = user);
  }

  final List<Widget> _pages = [
    const _DashboardTab(),
    const Placeholder(), // Map - replaced in full app
    const Placeholder(), // Reports
    const Placeholder(), // Alerts
    const Placeholder(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(user: _currentUser),
          _buildNavPlaceholder('Map', Icons.map_rounded, '/map'),
          _buildNavPlaceholder('Reports', Icons.list_alt_rounded, '/reports'),
          _buildNavPlaceholder('Alerts', Icons.notifications_active_rounded, '/alerts'),
          _buildNavPlaceholder('Profile', Icons.person_rounded, '/profile'),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 2
          ? _buildFAB()
          : null,
    );
  }

  Widget _buildNavPlaceholder(String title, IconData icon, String route) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('Navigate to $route', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'Home'),
              _navItem(1, Icons.map_rounded, 'Map'),
              _navItem(2, Icons.list_alt_rounded, 'Reports'),
              _navItem(3, Icons.notifications_active_rounded, 'Alerts'),
              _navItem(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isAlert = label == 'Alerts';

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, '/map');
          return;
        }
        if (index == 3) {
          Navigator.pushNamed(context, '/alerts');
          return;
        }
        if (index == 4) {
          Navigator.pushNamed(context, '/profile');
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 24,
                ),
                if (isAlert)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/report/new'),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      elevation: 4,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final CivicUser? user;
  const _DashboardTab({this.user});

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final alertService = AlertService();

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_getGreeting()},',
                                  style: AppTextStyles.bodyMediumWhite,
                                ),
                                Text(
                                  user?.displayName ?? 'Civic Citizen',
                                  style: AppTextStyles.h2White,
                                ),
                              ],
                            ),
                          ),
                          // Points badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.totalPoints ?? 0} pts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.levelTitle ?? 'Newcomer',
                        style: AppTextStyles.captionWhite.copyWith(
                          color: Colors.amber.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/alerts'),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active alert banner
                StreamBuilder<List<DisasterAlert>>(
                  stream: alertService.getActiveAlertsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return _AlertBanner(alert: snapshot.data!.first);
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 20),

                // Quick actions
                Text('Quick Actions', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                _QuickActions(),

                const SizedBox(height: 24),

                // Stats row
                _StatsRow(
                  totalReports: user?.totalReports ?? 0,
                  resolvedReports: user?.resolvedReports ?? 0,
                  upvotes: 0,
                ),

                const SizedBox(height: 24),

                // Recent reports
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Reports', style: AppTextStyles.h3),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                StreamBuilder<List<RoadReport>>(
                  stream: reportService.getReportsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _EmptyReports();
                    }
                    final reports = snapshot.data!.take(5).toList();
                    return Column(
                      children: reports
                          .map((r) => _ReportCard(report: r))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _AlertBanner extends StatelessWidget {
  final DisasterAlert alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getAlertColor(alert.type);
    final icon = AppUtils.getAlertIcon(alert.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.severityLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.circle, color: Colors.white70, size: 6),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE ALERT',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white70,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_road_rounded, 'Report\nIssue', AppColors.warning, '/report/new'),
      (Icons.map_rounded, 'View\nMap', AppColors.primary, '/map'),
      (Icons.warning_amber_rounded, 'Alerts', AppColors.secondary, '/alerts'),
      (Icons.leaderboard_rounded, 'Leaderboard', AppColors.accent, null),
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (a.$4 != null) Navigator.pushNamed(context, a.$4!);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: a.$3.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.$1, color: a.$3, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalReports;
  final int resolvedReports;
  final int upvotes;

  const _StatsRow({
    required this.totalReports,
    required this.resolvedReports,
    required this.upvotes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('Reports\nSubmitted', totalReports.toString(), Icons.flag_rounded, AppColors.primary),
        const SizedBox(width: 10),
        _StatCard('Issues\nResolved', resolvedReports.toString(), Icons.check_circle_rounded, AppColors.accent),
        const SizedBox(width: 10),
        _StatCard('Community\nUpvotes', upvotes.toString(), Icons.thumb_up_rounded, AppColors.warning),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h2.copyWith(color: color),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final RoadReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context, '/report/detail',
        arguments: report,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Severity indicator
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: AppUtils.getSeverityColor(report.severity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 4),
                  Text(
                    report.address,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('${report.upvotes}', style: AppTextStyles.caption),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        AppUtils.formatDate(report.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 56, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('No reports yet', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            'Be the first to report a road issue in your area!',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
