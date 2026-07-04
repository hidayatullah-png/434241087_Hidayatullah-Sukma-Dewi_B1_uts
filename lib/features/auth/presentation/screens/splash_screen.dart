// lib/features/auth/presentation/screens/splash_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../dashboard/presentation/screens/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // -- Animation controllers --
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo: fade + scale in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Text: fade + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Pulse: ring di belakang logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    // 1. Animasi logo
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();

    // 2. Animasi teks
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textController.forward();

    // 3. Pengecekan Sesi Supabase (Dijalankan bersamaan dengan waktu tunggu animasi)
    // Ambil sesi user saat ini dari memori lokal HP/Browser
    final session = Supabase.instance.client.auth.currentSession;
    
    // Jika ada sesi (berarti sudah pernah login dan belum expired/logout)
    if (session != null) {
      try {
        // Ambil data nama dan role dari tabel public.users
        final userData = await Supabase.instance.client
            .from('users')
            .select('name, role')
            .eq('id', session.user.id)
            .maybeSingle();

        if (userData != null && mounted) {
           // Pulihkan status authProvider di Riverpod
           ref.read(authProvider.notifier).setUser(
             name: userData['name'] ?? 'User',
             role: userData['role'] ?? 'user',
             email: session.user.email ?? '',
           );
        }
      } catch (e) {
        // Jika gagal mengambil data (misal internet putus), abaikan saja.
        // Nanti biarkan user masuk ke Dashboard dengan data default,
        print('Gagal memulihkan profil user: $e');
      }
    }

    // 4. Sisa waktu tunggu animasi agar transisinya tidak terpotong tiba-tiba
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    
    _navigate();
  }

  void _navigate() {
    final auth = ref.read(authProvider);
    
    final destination = auth.isLoggedIn
        ? const MainScreen() 
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wrnDarkBg,
      body: Stack(
        children: [
          // -- Background shapes -- //
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.wrnShapePurple.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.wrnShapeRose.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.wrnShapePurple.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),

          // -- Konten utama -- //
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dengan pulse ring
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring luar
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.wrnBtsPurple.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        // Pulse ring dalam
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.wrnBtsPurple.withOpacity(0.08),
                            ),
                          ),
                        ),

                        // Logo container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.wrnBtsPurple,
                                AppColors.wrnDeepPurple,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.wrnBtsPurple.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Teks app name + tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        // App name
                        const Text(
                          'E-Ticketing',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),

                        // Accent word
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.wrnButtonGradient.createShader(bounds),
                          child: const Text(
                            'Helpdesk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'Laporkan. Pantau. Selesaikan.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -- Loading indicator bawah -- //
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.wrnLightPurple.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat aplikasi...',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // -- Versi app -- //
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: const Text(
                'v2.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
