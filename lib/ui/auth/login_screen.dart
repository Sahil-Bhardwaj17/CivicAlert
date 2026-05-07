import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signInWithGoogle();

      // user cancelled
      if (credential == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // success — navigate regardless
      await _authService.createOrUpdateUser(credential.user!);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      // Even if error, check if user is already signed in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Auth succeeded, just navigate
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          AppUtils.showSnackBar(
            context,
            'Sign-in failed. Try again.',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHeader(size),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text('Welcome to CivicAlert', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to report road issues and receive real-time disaster alerts in your area.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 36),

                    // Google button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildFeatures(),
                    const Spacer(),
                    Center(
                      child: Text(
                        'By signing in, you agree to our Terms & Privacy Policy',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.32,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: 16),
            Text('CivicAlert',
                style: AppTextStyles.h1White.copyWith(fontSize: 30)),
            const SizedBox(height: 6),
            Text('Report. Alert. Act.',
                style: AppTextStyles.bodyMediumWhite.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      (Icons.report_problem_rounded, 'Report road issues with AI severity detection', AppColors.warning),
      (Icons.warning_amber_rounded, 'Real-time disaster alerts for your area', AppColors.secondary),
      (Icons.people_rounded, 'Join community to keep roads safe', AppColors.accent),
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: f.$3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(f.$1, color: f.$3, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(f.$2, style: AppTextStyles.bodyMedium)),
          ],
        ),
      )).toList(),
    );
  }
}