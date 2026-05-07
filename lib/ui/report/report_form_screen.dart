// lib/ui/report/report_form_screen.dart
import 'dart:io';
import 'package:civicalert/core/constants/app_colors.dart';
import 'package:civicalert/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/report_model.dart';
import '../../core/services/report_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/app_utils.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _reportService = ReportService();
  final _aiService = AIService();
  final _locationService = LocationService();

  List<XFile> _selectedImages = [];
  ReportCategory _selectedCategory = ReportCategory.pothole;
  SeverityLevel _selectedSeverity = SeverityLevel.medium;
  SeverityAnalysisResult? _aiAnalysis;

  double? _latitude;
  double? _longitude;
  String _address = 'Fetching location...';

  bool _isLoadingLocation = true;
  bool _isAnalyzingAI = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);

    // Request permission explicitly
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _address = 'Location permission denied';
          _isLoadingLocation = false;
        });
        AppUtils.showSnackBar(
          context,
          'Please allow location to auto-fill address',
          isError: true,
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _address = address;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Could not get location';
          _isLoadingLocation = false;
        });
      }
    }
  }
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(4).toList();
      });
      if (_selectedImages.isNotEmpty) {
        _analyzeWithAI();
      }
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImages = [..._selectedImages, image].take(4).toList();
      });
      _analyzeWithAI();
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isAnalyzingAI = true);

    final result = await _aiService.analyzeRoadIssue(
      File(_selectedImages.first.path),
    );

    if (mounted) {
      setState(() {
        _aiAnalysis = result;
        _selectedSeverity = result.severity;
        _selectedCategory = result.category;
        _isAnalyzingAI = false;
        if (_titleController.text.isEmpty) {
          _titleController.text =
          '${AppUtils.getCategoryLabel(result.category)} at ${'$_address'.split(',').first}';
        }
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      AppUtils.showSnackBar(context, 'Please add at least one photo', isError: true);
      return;
    }
    if (_latitude == null || _longitude == null) {
      AppUtils.showSnackBar(context, 'Location not available', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final report = RoadReport(
        id: '',
        userId: user?.uid ?? '',
        userPhone: user?.phoneNumber ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        severity: _selectedSeverity,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        imageUrls: [],
        createdAt: DateTime.now(),
      );

      await _reportService.createReport(
        report,
        _selectedImages.map((x) => File(x.path)).toList(),
      );

      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'Report submitted! +10 points earned.',
          isSuccess: true,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppUtils.showSnackBar(context, 'Failed to submit: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Road Issue', style: AppTextStyles.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location card
              _buildLocationCard(),
              const SizedBox(height: 16),

              // Photos section
              _buildPhotosSection(),
              const SizedBox(height: 16),

              // AI analysis result
              if (_aiAnalysis != null) _buildAIAnalysisCard(),
              if (_aiAnalysis != null) const SizedBox(height: 16),

              // Category selection
              _buildSectionTitle('Category'),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // Severity selection
              _buildSectionTitle('Severity Level'),
              const SizedBox(height: 8),
              _buildSeveritySelector(),
              const SizedBox(height: 16),

              // Title
              _buildSectionTitle('Issue Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: AppTextStyles.bodyLarge,
                decoration: _inputDecoration('e.g., Large pothole on NH-1 near petrol pump'),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                maxLength: 100,
              ),
              const SizedBox(height: 12),

              // Description
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: AppTextStyles.bodyLarge,
                decoration: _inputDecoration('Describe the issue, surrounding area, danger level...'),
                maxLines: 4,
                maxLength: 500,
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Submitting...', style: AppTextStyles.buttonLarge),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 20),
                      const SizedBox(width: 8),
                      const Text('Submit Report', style: AppTextStyles.buttonLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Location', style: AppTextStyles.labelSmall),
                const SizedBox(height: 2),
                _isLoadingLocation
                    ? const SizedBox(
                  height: 14,
                  width: 100,
                  child: LinearProgressIndicator(),
                )
                    : Text(
                  _address,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 20),
            onPressed: _fetchLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Photos'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI Analysis',
                style: AppTextStyles.chip.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          color: AppColors.primary.withOpacity(0.7), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected images
              ..._selectedImages.map((img) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(img.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 14,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedImages.remove(img));
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ),
        if (_isAnalyzingAI) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('Analyzing with Gemini AI...', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAIAnalysisCard() {
    final analysis = _aiAnalysis!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Gemini AI Analysis',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              const Spacer(),
              Text(
                '${(analysis.confidence * 100).round()}% confidence',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(analysis.description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    analysis.estimatedRisk,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReportCategory.values.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppUtils.getCategoryIcon(cat),
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  AppUtils.getCategoryLabel(cat),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeveritySelector() {
    return Row(
      children: SeverityLevel.values.map((sev) {
        final isSelected = _selectedSeverity == sev;
        final color = AppUtils.getSeverityColor(sev);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSeverity = sev),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.3),
                ),
              ),
              child: Text(
                AppUtils.getSeverityLabel(sev),
                textAlign: TextAlign.center,
                style: AppTextStyles.chip.copyWith(
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.labelLarge);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}