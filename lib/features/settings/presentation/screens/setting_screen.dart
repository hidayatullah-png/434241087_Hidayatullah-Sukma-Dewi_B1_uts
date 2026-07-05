import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/font_size_provider.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final fontNotifier = ref.read(fontSizeProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Ukuran Font ───────────────────────────────────
            _SectionLabel(text: 'UKURAN FONT', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _SettingCard(
              isDark: isDark,
              cs: cs,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.wrnBtsPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.text_fields_rounded,
                              color: AppColors.wrnBtsPurple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ukuran Teks',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  fontSize.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.wrnLightPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Font size selector
                      Row(
                        children: FontSizeOption.values.map((option) {
                          final isSelected = fontSize == option;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => fontNotifier.setSize(option),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(
                                  right: option != FontSizeOption.large ? 8 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.wrnBtsPurple
                                      : isDark
                                      ? AppColors.wrnDarkBg
                                      : cs.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.wrnBtsPurple
                                        : isDark
                                        ? AppColors.wrnShapePurple.withOpacity(
                                            0.3,
                                          )
                                        : cs.outlineVariant.withOpacity(0.5),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _fontPreview(option),
                                      style: TextStyle(
                                        fontSize: _previewSize(option),
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.85)
                                            : cs.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Preview teks
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.wrnDarkBg
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.wrnShapePurple.withOpacity(0.2)
                                : cs.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preview Teks',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Printer lantai 3 tidak bisa digunakan',
                              style: TextStyle(
                                fontSize: 14 * fontSize.scale,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Error code 0x03 saat mencetak dokumen penting.',
                              style: TextStyle(
                                fontSize: 12 * fontSize.scale,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Tentang ───────────────────────────────────────
            _SectionLabel(text: 'TENTANG', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _SettingCard(
              isDark: isDark,
              cs: cs,
              children: [
                _SettingTile(
                  icon: Icons.info_outline,
                  title: 'Versi Aplikasi',
                  subtitle: '2.0.0',
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                  showChevron: false,
                ),
                _Divider(cs: cs, isDark: isDark),
                _SettingTile(
                  icon: Icons.school_outlined,
                  title: 'Dibuat untuk',
                  subtitle: 'E-Ticketing Masalah IT',
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                  showChevron: false,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _fontPreview(FontSizeOption option) {
    switch (option) {
      case FontSizeOption.small:
        return 'Aa';
      case FontSizeOption.normal:
        return 'Aa';
      case FontSizeOption.large:
        return 'Aa';
    }
  }

  double _previewSize(FontSizeOption option) {
    switch (option) {
      case FontSizeOption.small:
        return 14;
      case FontSizeOption.normal:
        return 18;
      case FontSizeOption.large:
        return 22;
    }
  }
}

// ── Helper Widgets ─────────────────────────────────────────────

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
      style: theme.textTheme.labelSmall?.copyWith(
        color: cs.onSurface.withOpacity(0.45),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final ColorScheme cs;
  const _SettingCard({
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

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;
  final bool showChevron;
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.cs,
    required this.theme,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
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

class _Divider extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  const _Divider({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: isDark
          ? AppColors.wrnShapePurple.withOpacity(0.2)
          : cs.outlineVariant.withOpacity(0.35),
    );
  }
}
