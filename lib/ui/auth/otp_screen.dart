// // lib/ui/auth/otp_screen.dart
// import 'dart:async';
// import 'package:civicalert/core/constant/app_colors.dart';
// import 'package:civicalert/core/constant/app_text_styles.dart';
// import 'package:flutter/material.dart';
// import 'package:pinput/pinput.dart';
// import '../../core/services/auth_service.dart';
// import '../../core/utils/app_utils.dart';
//
// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key});
//
//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }
//
// class _OtpScreenState extends State<OtpScreen> {
//   final _authService = AuthService();
//   final _pinController = TextEditingController();
//   final _focusNode = FocusNode();
//
//   bool _isLoading = false;
//   bool _canResend = false;
//   int _secondsRemaining = 60;
//   Timer? _timer;
//   String _phone = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//       if (args != null) {
//         setState(() => _phone = args['phone'] ?? '');
//       }
//     });
//   }
//
//   void _startTimer() {
//     _secondsRemaining = 60;
//     _canResend = false;
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           if (_secondsRemaining > 0) {
//             _secondsRemaining--;
//           } else {
//             _canResend = true;
//             timer.cancel();
//           }
//         });
//       }
//     });
//   }
//
//   Future<void> _verifyOTP() async {
//     final otp = _pinController.text.trim();
//     if (otp.length != 6) {
//       AppUtils.showSnackBar(context, 'Please enter the 6-digit OTP', isError: true);
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final credential = await _authService.verifyOTP(otp);
//       if (credential?.user != null) {
//         await _authService.createOrUpdateUser(credential!.user!);
//         if (mounted) {
//           AppUtils.showSnackBar(context, 'Login successful!', isSuccess: true);
//           Navigator.pushReplacementNamed(context, '/home');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         AppUtils.showSnackBar(
//           context,
//           'Invalid OTP. Please try again.',
//           isError: true,
//         );
//         _pinController.clear();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _pinController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final defaultTheme = PinTheme(
//       width: 52,
//       height: 58,
//       textStyle: AppTextStyles.h3.copyWith(color: AppColors.primary),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.border, width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadow,
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//     );
//
//     final focusedTheme = defaultTheme.copyDecorationWith(
//       border: Border.all(color: AppColors.primary, width: 2),
//       boxShadow: [
//         BoxShadow(
//           color: AppColors.primary.withOpacity(0.2),
//           blurRadius: 10,
//           offset: const Offset(0, 3),
//         ),
//       ],
//     );
//
//     final submittedTheme = defaultTheme.copyDecorationWith(
//       color: AppColors.primary.withOpacity(0.08),
//       border: Border.all(color: AppColors.primary),
//     );
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 20),
//
//             // Icon
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.phone_android_rounded,
//                 color: AppColors.primary,
//                 size: 40,
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             Text('Verify OTP', style: AppTextStyles.h1),
//             const SizedBox(height: 10),
//             Text(
//               'We sent a 6-digit code to',
//               style: AppTextStyles.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               _phone,
//               style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
//             ),
//             const SizedBox(height: 40),
//
//             // PIN input
//             Pinput(
//               length: 6,
//               controller: _pinController,
//               focusNode: _focusNode,
//               autofocus: true,
//               defaultPinTheme: defaultTheme,
//               focusedPinTheme: focusedTheme,
//               submittedPinTheme: submittedTheme,
//               onCompleted: (_) => _verifyOTP(),
//               hapticFeedbackType: HapticFeedbackType.lightImpact,
//             ),
//             const SizedBox(height: 36),
//
//             // Verify button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _verifyOTP,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                   height: 22,
//                   width: 22,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2.5,
//                   ),
//                 )
//                     : const Text('Verify OTP', style: AppTextStyles.buttonLarge),
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             // Resend timer
//             if (!_canResend)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Resend OTP in ',
//                     style: AppTextStyles.bodyMedium,
//                   ),
//                   Text(
//                     '${_secondsRemaining}s',
//                     style: AppTextStyles.labelLarge.copyWith(
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ],
//               )
//             else
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: Text(
//                   'Resend OTP',
//                   style: AppTextStyles.labelLarge.copyWith(
//                     color: AppColors.primary,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//               ),
//
//             const SizedBox(height: 40),
//
//             // Info box
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.06),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.primary.withOpacity(0.2)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.info_outline_rounded,
//                       color: AppColors.primary, size: 18),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       'OTP is valid for 10 minutes. Do not share it with anyone.',
//                       style: AppTextStyles.bodySmall.copyWith(
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }