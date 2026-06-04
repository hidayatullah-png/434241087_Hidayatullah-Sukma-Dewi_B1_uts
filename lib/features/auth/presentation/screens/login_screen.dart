import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../dashboard/presentation/screens/main_screen.dart';
import '../../../../core/providers/navigation_provider.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

// -- Dummy Users Dihapus --

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Catatan: Supabase secara default menggunakan Email untuk login.
    // Kita anggap input 'username' ini diisi dengan email oleh user.
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    // Validasi kosong
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = 'Email/Username dan password tidak boleh kosong',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Eksekusi Login ke Supabase
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final User? user = res.user;

      if (user != null && mounted) {
        // 2. Ambil data tambahan (role & nama) dari tabel database
        // Asumsi kamu punya tabel 'users' untuk menyimpan role & nama.
        // Jika belum buat tabelnya, kode ini sementara akan memberi nilai default.
        final userData = await Supabase.instance.client
            .from('users')
            .select('name, role')
            .eq('id', user.id)
            .maybeSingle();

        final name = userData?['name'] ?? 'User';
        final role = userData?['role'] ?? 'user';

        // 3. Set auth state via Riverpod
        ref
            .read(authProvider.notifier)
            .setUser(name: name, role: role, email: user.email ?? '');

        // 4. Reset index navigasi ke 0 (menggunakan setIndex dari Notifier baru)
        ref.read(navIndexProvider.notifier).setIndex(0);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      // Menangkap error spesifik dari Supabase (misal: password salah)
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      // Menangkap error lainnya (misal: koneksi terputus)
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wrnDarkBg,
      body: Stack(
        children: [
          // -- Background shapes --
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.wrnShapePurple.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.wrnShapeRose.withOpacity(0.2),
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

          // -- Form --
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Welcome\nBack',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Username field
                  _buildInputField(
                    controller: _usernameController,
                    hint: 'Username / Email',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  _buildPasswordField(),

                  // Error message
                  if (_errorMessage != null) ...[
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
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFCF6679),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 40),

                  const SizedBox(height: 20),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wrnBtsPurple,
                        disabledBackgroundColor: AppColors.wrnBtsPurple
                            .withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordScreen(),
                        ),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppColors.textGrey),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.wrnDarkInput,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textWhite),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey),
          prefixIcon: Icon(icon, color: AppColors.textGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.wrnDarkInput,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: AppColors.textWhite),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(color: AppColors.textGrey),
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textGrey),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textGrey,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
