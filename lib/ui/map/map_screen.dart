// lib/ui/map/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/report_model.dart';
import '../../core/models/alert_model.dart';
import '../../core/services/report_service.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/app_utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _reportService = ReportService();
  final _alertService = AlertService();
  final _locationService = LocationService();
  final _mapController = MapController();

  LatLng _center = const LatLng(30.9095, 75.8573); // Ludhiana default
  double _zoom = 13.0;
  bool _isLoadingLocation = true;
  bool _showReports = true;
  bool _showAlerts = true;
  bool _showSafeZones = false;

  List<RoadReport> _reports = [];
  List<DisasterAlert> _alerts = [];
  RoadReport? _selectedReport;
  DisasterAlert? _selectedAlert;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadData();
  }

  Future<void> _loadLocation() async {
    // First explicitly ask permission
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Show message to user
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'Location permission required to show your area',
          isError: true,
        );
        setState(() => _isLoadingLocation = false);
      }
      return;
    }

    // Permission granted — get actual position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        // Move map to actual location
        _mapController.move(_center, 15.0);
        // Reload data for new location
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        AppUtils.showSnackBar(
          context,
          'Could not get location. Check GPS is on.',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadData() async {
    final reports = await _reportService.getNearbyReports(
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
    final alerts = await _alertService.getNearbyAlerts(
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
    if (mounted) {
      setState(() {
        _reports = reports;
        _alerts = alerts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              onTap: (_, __) {
                setState(() {
                  _selectedReport = null;
                  _selectedAlert = null;
                });
              },
            ),
            children: [
              // Base tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.civicalert.app',
              ),

              // Alert radius circles
              if (_showAlerts)
                CircleLayer(
                  circles: _alerts.map((alert) => CircleMarker(
                    point: LatLng(alert.latitude, alert.longitude),
                    radius: alert.radiusKm * 800,
                    color: AppUtils.getAlertColor(alert.type).withOpacity(0.15),
                    borderColor: AppUtils.getAlertColor(alert.type).withOpacity(0.5),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  )).toList(),
                ),

              // Report markers
              if (_showReports)
                MarkerLayer(
                  markers: _reports.map((report) => Marker(
                    point: LatLng(report.latitude, report.longitude),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedReport = report;
                        _selectedAlert = null;
                      }),
                      child: _ReportMarker(report: report),
                    ),
                  )).toList(),
                ),

              // Alert markers
              if (_showAlerts)
                MarkerLayer(
                  markers: _alerts.map((alert) => Marker(
                    point: LatLng(alert.latitude, alert.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedAlert = alert;
                        _selectedReport = null;
                      }),
                      child: _AlertMarker(alert: alert),
                    ),
                  )).toList(),
                ),

              // Safe zone markers
              if (_showSafeZones)
                MarkerLayer(
                  markers: _alerts
                      .expand((alert) => alert.safeZones)
                      .map((zone) => Marker(
                    point: LatLng(zone.latitude, zone.longitude),
                    width: 34,
                    height: 34,
                    child: _SafeZoneMarker(zone: zone),
                  ))
                      .toList(),
                ),

              // Current location marker
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Back button
                    _MapButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    // Title card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_reports.length} Issues · ${_alerts.length} Alerts',
                              style: AppTextStyles.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Refresh
                    _MapButton(
                      icon: Icons.refresh_rounded,
                      onTap: _loadData,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer toggle chips
          Positioned(
            top: 80,
            left: 12,
            child: SafeArea(
              child: Column(
                children: [
                  _LayerChip(
                    label: 'Reports',
                    isActive: _showReports,
                    color: AppColors.warning,
                    onTap: () => setState(() => _showReports = !_showReports),
                  ),
                  const SizedBox(height: 6),
                  _LayerChip(
                    label: 'Alerts',
                    isActive: _showAlerts,
                    color: AppColors.secondary,
                    onTap: () => setState(() => _showAlerts = !_showAlerts),
                  ),
                  const SizedBox(height: 6),
                  _LayerChip(
                    label: 'Safe Zones',
                    isActive: _showSafeZones,
                    color: AppColors.accent,
                    onTap: () =>
                        setState(() => _showSafeZones = !_showSafeZones),
                  ),
                ],
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 12,
            bottom: 180,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    _zoom = (_zoom + 1).clamp(5.0, 18.0);
                    _mapController.move(_center, _zoom);
                  },
                ),
                const SizedBox(height: 6),
                _MapButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    _zoom = (_zoom - 1).clamp(5.0, 18.0);
                    _mapController.move(_center, _zoom);
                  },
                ),
                const SizedBox(height: 6),
                _MapButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _mapController.move(_center, 15),
                ),
              ],
            ),
          ),

          // Report FAB
          Positioned(
            right: 12,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/report/new'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),

          // Bottom detail card
          if (_selectedReport != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ReportDetailCard(
                report: _selectedReport!,
                onClose: () => setState(() => _selectedReport = null),
                onView: () => Navigator.pushNamed(
                  context,
                  '/report/detail',
                  arguments: _selectedReport,
                ),
              ),
            ),

          if (_selectedAlert != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _AlertDetailCard(
                alert: _selectedAlert!,
                onClose: () => setState(() => _selectedAlert = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportMarker extends StatelessWidget {
  final RoadReport report;
  const _ReportMarker({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getSeverityColor(report.severity);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        AppUtils.getCategoryIcon(report.category),
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _AlertMarker extends StatelessWidget {
  final DisasterAlert alert;
  const _AlertMarker({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getAlertColor(alert.type);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: Icon(
        AppUtils.getAlertIcon(alert.type),
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _SafeZoneMarker extends StatelessWidget {
  final SafeZone zone;
  const _SafeZoneMarker({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 16),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _LayerChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
        ),
        child: Text(
          label,
          style: AppTextStyles.chip.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ReportDetailCard extends StatelessWidget {
  final RoadReport report;
  final VoidCallback onClose;
  final VoidCallback onView;
  const _ReportDetailCard({
    required this.report,
    required this.onClose,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getSeverityColor(report.severity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMedium, blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.title,
                          style: AppTextStyles.h4, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(report.address,
                          style: AppTextStyles.bodySmall, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(label: AppUtils.getSeverityLabel(report.severity), color: color),
                const SizedBox(width: 8),
                _InfoChip(
                  label: AppUtils.getStatusLabel(report.status),
                  color: AppUtils.getStatusColor(report.status),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertDetailCard extends StatelessWidget {
  final DisasterAlert alert;
  final VoidCallback onClose;
  const _AlertDetailCard({required this.alert, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getAlertColor(alert.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMedium, blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppUtils.getAlertIcon(alert.type), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title,
                          style: AppTextStyles.h4, maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text('${alert.typeLabel} · ${alert.severityLabel}',
                          style: AppTextStyles.bodySmall.copyWith(color: color)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
            if (alert.safeZones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.local_hospital_rounded,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${alert.safeZones.length} safe zones nearby',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.chip.copyWith(color: color)),
    );
  }
}
