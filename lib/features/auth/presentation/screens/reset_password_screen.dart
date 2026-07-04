// lib/features/auth/presentation/screens/reset_password_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email tidak boleh kosong');
      return;
    }

    // Validasi format email sederhana
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Format email tidak valid');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kirim email reset password via Supabase Auth
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'io.supabase.srs_mobile://reset-callback/', // sesuaikan dengan deep link app kamu
      );

      if (!mounted) return;
      setState(() => _isEmailSent = true);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wrnDarkBg,
      body: Stack(
        children: [
          // ── Background shapes ──
          Positioned(
            top: 100,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.wrnShapePurple.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.wrnShapeRose.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Konten ──
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textWhite,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: _isEmailSent
                        ? _SuccessView(
                            email: _emailController.text.trim(),
                            onBack: () => Navigator.pop(context),
                          )
                        : _FormView(
                            emailController: _emailController,
                            isLoading: _isLoading,
                            errorMessage: _errorMessage,
                            onSubmit: _handleResetPassword,
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
}

// ── Form View ──────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _FormView({
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Icon kunci
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.wrnBtsPurple.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: AppColors.wrnLightPurple,
            size: 36,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Lupa\nPassword?',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 38,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk reset password kamu.',
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        // Email field
        Container(
          decoration: BoxDecoration(
            color: AppColors.wrnDarkInput,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: const InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(color: AppColors.textGrey),
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.textGrey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
            ),
          ),
        ),

        // Error
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFCF6679),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFCF6679),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wrnBtsPurple,
              disabledBackgroundColor: AppColors.wrnBtsPurple.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Kirim Link Reset',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Kembali ke Login',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Success View ───────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessView({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Icon sukses
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.wrnBtsPurple.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.wrnLightPurple,
            size: 52,
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'Email Terkirim!',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          'Link reset password telah dikirim ke\n$email\n\nCek inbox atau folder spam kamu.',
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Kembali ke login
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wrnBtsPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Kembali ke Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Kirim ulang
        TextButton(
          onPressed: onBack,
          child: const Text(
            'Tidak menerima email? Coba lagi',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}