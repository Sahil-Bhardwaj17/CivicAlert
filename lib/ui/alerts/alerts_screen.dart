// lib/ui/alerts/alerts_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/alert_model.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/app_utils.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _alertService = AlertService();
  final _locationService = LocationService();

  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Disaster Alerts', style: AppTextStyles.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active Alerts'),
            Tab(text: 'Nearby'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveAlertsTab(alertService: _alertService),
          _NearbyAlertsTab(
            alertService: _alertService,
            userLat: _userLat,
            userLng: _userLng,
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertsTab extends StatelessWidget {
  final AlertService alertService;
  const _ActiveAlertsTab({required this.alertService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DisasterAlert>>(
      stream: alertService.getActiveAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _NoAlertsWidget();
        }

        final alerts = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${alerts.length} active alert${alerts.length > 1 ? 's' : ''} in your region',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),

            ...alerts.map((alert) => _AlertCard(alert: alert)),
          ],
        );
      },
    );
  }
}

class _NearbyAlertsTab extends StatelessWidget {
  final AlertService alertService;
  final double? userLat;
  final double? userLng;

  const _NearbyAlertsTab({
    required this.alertService,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    if (userLat == null || userLng == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 60, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Location not available', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text('Enable location to see nearby alerts',
                style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return FutureBuilder<List<DisasterAlert>>(
      future: alertService.getNearbyAlerts(
        latitude: userLat!,
        longitude: userLng!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _NoAlertsWidget(isNearby: true);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.map((a) => _AlertCard(alert: a)).toList(),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DisasterAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getAlertColor(alert.type);
    final icon = AppUtils.getAlertIcon(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
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
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AlertSeverityBadge(severity: alert.severity),
                          const SizedBox(width: 8),
                          Text(
                            alert.typeLabel.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
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
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 12),

                // Affected areas
                if (alert.affectedAreas.isNotEmpty) ...[
                  Text('Affected Areas', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: alert.affectedAreas
                        .map((area) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        area,
                        style: AppTextStyles.chip
                            .copyWith(color: color),
                      ),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Safe zones summary
                if (alert.safeZones.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${alert.safeZones.length} Safe Zone${alert.safeZones.length > 1 ? 's' : ''} Available',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.accent),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            _showSafeZones(context, alert),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  ...alert.safeZones.take(2).map((zone) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(zone.name,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (zone.contactNumber != null)
                          Text(zone.contactNumber!,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  )),
                ],

                const SizedBox(height: 10),

                // View on map button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/map'),
                    icon: Icon(Icons.map_rounded, color: color, size: 16),
                    label: Text('View on Map',
                        style: TextStyle(color: color)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                // Timestamp & source
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      AppUtils.formatDate(alert.createdAt),
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    Text(
                      'Source: ${alert.source}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSafeZones(BuildContext context, DisasterAlert alert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Safe Zones', style: AppTextStyles.h3),
                const Spacer(),
                Text(
                  '${alert.safeZones.length} locations',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            itemCount: alert.safeZones.length,
            itemBuilder: (_, i) {
              final zone = alert.safeZones[i];
              return ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: AppColors.accent, size: 18),
                ),
                title: Text(zone.name, style: AppTextStyles.labelLarge),
                subtitle: zone.contactNumber != null
                    ? Text(zone.contactNumber!, style: AppTextStyles.bodySmall)
                    : null,
                trailing: zone.capacity != null
                    ? Text('${zone.capacity} cap',
                    style: AppTextStyles.caption)
                    : null,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AlertSeverityBadge extends StatelessWidget {
  final AlertSeverity severity;
  const _AlertSeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final colors = {
      AlertSeverity.advisory: Colors.blue,
      AlertSeverity.watch: Colors.orange,
      AlertSeverity.warning: Colors.deepOrange,
      AlertSeverity.emergency: Colors.red,
    };
    final color = colors[severity] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NoAlertsWidget extends StatelessWidget {
  final bool isNearby;
  const _NoAlertsWidget({this.isNearby = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 50, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text('All Clear!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              isNearby
                  ? 'No active disaster alerts in your area. Stay safe!'
                  : 'No active disaster alerts at this time. Stay safe!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will receive push notifications if a disaster alert is issued for your area.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
