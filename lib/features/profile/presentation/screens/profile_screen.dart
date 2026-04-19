import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _localAvatar;
  final _picker = ImagePicker();

  // -- Pick avatar --

  Future<void> _pickAvatar() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.wrnDarkInput : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.wrnBtsPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.wrnBtsPurple,
                  ),
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    setState(() => _localAvatar = File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.wrnBtsPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.wrnBtsPurple,
                  ),
                ),
                title: const Text('Pilih dari Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    setState(() => _localAvatar = File(picked.path));
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // -- Edit profil dialog --

  void _showEditProfileDialog(AuthState auth) {
    final nameController = TextEditingController(text: auth.name);
    final emailController = TextEditingController(text: auth.email);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.wrnDarkInput : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogTextField(
              controller: nameController,
              label: 'Nama',
              icon: Icons.person_outline,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _DialogTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: panggil API update profil
              ref
                  .read(authProvider.notifier)
                  .setUser(
                    name: nameController.text.trim(),
                    role: auth.role,
                    email: emailController.text.trim(),
                  );
              Navigator.pop(ctx);
              _showSnack('Profil berhasil diperbarui');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wrnBtsPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // -- Ganti password dialog --

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.wrnDarkInput : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Ganti Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogTextField(
                controller: oldPassController,
                label: 'Password Lama',
                icon: Icons.lock_outline,
                isDark: isDark,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: newPassController,
                label: 'Password Baru',
                icon: Icons.lock_reset_outlined,
                isDark: isDark,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: confirmPassController,
                label: 'Konfirmasi Password',
                icon: Icons.lock_reset_outlined,
                isDark: isDark,
                isPassword: true,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFCF6679),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFCF6679),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPassController.text != confirmPassController.text) {
                  setDialogState(
                    () => errorText = 'Konfirmasi password tidak cocok',
                  );
                  return;
                }
                if (newPassController.text.length < 6) {
                  setDialogState(
                    () => errorText = 'Password minimal 6 karakter',
                  );
                  return;
                }
                // TODO: panggil API ganti password
                Navigator.pop(ctx);
                _showSnack('Password berhasil diperbarui');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wrnBtsPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // -- Logout confirm --

  void _showLogoutConfirm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.wrnDarkInput : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Kamu akan keluar dari aplikasi. Yakin ingin logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              // Navigate ke login, hapus semua route
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF6679),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.wrnBtsPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -- Avatar + info --
            Center(
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.wrnBtsPurple.withOpacity(
                          0.15,
                        ),
                        backgroundImage: _localAvatar != null
                            ? FileImage(_localAvatar!)
                            : null,
                        child: _localAvatar == null
                            ? Text(
                                auth.name.isNotEmpty
                                    ? auth.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.wrnBtsPurple,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      // Edit avatar button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.wrnBtsPurple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.wrnDarkBg
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Nama
                  Text(
                    auth.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    auth.email.isNotEmpty ? auth.email : '-',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.wrnBtsPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.wrnBtsPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      auth.role.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.wrnBtsPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // -- Menu section: Akun --
            _SectionLabel(text: 'Akun', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _MenuCard(
              isDark: isDark,
              cs: cs,
              children: [
                _MenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profil',
                  onTap: () => _showEditProfileDialog(auth),
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                ),
                _MenuDivider(cs: cs, isDark: isDark),
                _MenuItem(
                  icon: Icons.lock_reset_outlined,
                  label: 'Ganti Password',
                  onTap: _showChangePasswordDialog,
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // -- Menu section: Preferensi --
            _SectionLabel(text: 'Preferensi', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _MenuCard(
              isDark: isDark,
              cs: cs,
              children: [
                // Toggle dark mode
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.wrnBtsPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: AppColors.wrnBtsPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Dark Mode',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: isDark,
                        onChanged: (_) => themeNotifier.toggle(),
                        activeColor: AppColors.wrnBtsPurple,
                        activeTrackColor: AppColors.wrnBtsPurple.withOpacity(
                          0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // -- Menu section: Lainnya --
            _SectionLabel(text: 'Lainnya', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _MenuCard(
              isDark: isDark,
              cs: cs,
              children: [
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Tentang Aplikasi',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'E-Ticketing Helpdesk',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          '© 2026 Sukma Dewi\nTotally handmade with ❤️(anjay)',
                    );
                  },
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // -- Logout button --
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showLogoutConfirm,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFCF6679),
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFCF6679),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// -- Helper Widgets --

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  final ThemeData theme;
  const _SectionLabel({
    required this.text,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: cs.onSurface.withOpacity(0.45),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final ColorScheme cs;
  const _MenuCard({
    required this.children,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrnDarkInput : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.wrnShapePurple.withOpacity(0.25)
              : cs.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.wrnBtsPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.wrnBtsPurple, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: cs.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  const _MenuDivider({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 0,
      color: isDark
          ? AppColors.wrnShapePurple.withOpacity(0.2)
          : cs.outlineVariant.withOpacity(0.35),
    );
  }
}

class _DialogTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isPassword;
  final TextInputType? keyboardType;

  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  State<_DialogTextField> createState() => _DialogTextFieldState();
}

class _DialogTextFieldState extends State<_DialogTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.wrnDarkBg : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? AppColors.wrnShapePurple.withOpacity(0.25)
              : cs.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: cs.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: cs.onSurface.withOpacity(0.4),
            size: 20,
          ),
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cs.onSurface.withOpacity(0.4),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
