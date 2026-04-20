import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../../../tickets/presentation/widgets/recent_ticket_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/screens/create_ticket_screen.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/screens/ticket_list_screen.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isAdminOrHelpdesk = auth.role == 'admin' || auth.role == 'helpdesk';

    return Scaffold(
      // Background sudah di-handle theme (wrnDarkBg / white)
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: cs.primary)),
          error: (e, _) =>
              _ErrorState(onRetry: () => ref.refresh(dashboardProvider)),
          data: (data) => RefreshIndicator(
            color: cs.primary,
            onRefresh: () async => ref.refresh(dashboardProvider),
            child: CustomScrollView(
              slivers: [
                // -- App Bar --
                SliverAppBar(
                  floating: true,
                  backgroundColor: isDark
                      ? AppColors.wrnDarkBg
                      : theme.scaffoldBackgroundColor,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang 👋',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                      ),
                      Text(
                        auth.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Role badge
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        auth.role.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Notification bell
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: cs.onSurface,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (data.unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cs.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                // -- Body --
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),

                      // -- Tampilan Utama (admin/helpdesk only) --
                      _SectionLabel(
                        text: isAdminOrHelpdesk
                            ? 'Tampilan Semua Tiket'
                            : 'Tiket Saya',
                      ),
                      const SizedBox(height: 12),

                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            label: 'Total Tiket',
                            value: '${data.totalTickets}',
                            icon: Icons.confirmation_number_outlined,
                            accentColor: AppColors.wrnDeepPurple,
                          ),
                          StatCard(
                            label: 'Open',
                            value: '${data.openTickets}',
                            icon: Icons.inbox_outlined,
                            accentColor: AppColors.wrnShapeRose,
                          ),
                          StatCard(
                            label: 'In Progress',
                            value: '${data.inProgressTickets}',
                            icon: Icons.autorenew_rounded,
                            accentColor: AppColors.wrnBtsPurple,
                          ),
                          StatCard(
                            label: 'Selesai',
                            value: '${data.resolvedTickets}',
                            icon: Icons.check_circle_outline,
                            accentColor: AppColors.wrnLightPurple,
                          ),
                        ],
                      ),

                      // -- Unassigned alert (admin/helpdesk only) --
                      if (isAdminOrHelpdesk && data.unassignedTickets > 0) ...[
                        const SizedBox(height: 20),
                        _SectionLabel(text: 'Perlu Perhatian'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.wrnShapeRose.withOpacity(
                              isDark ? 0.12 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.wrnShapeRose.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.wrnShapeRose,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data.unassignedTickets} tiket belum di-assign',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                    ),
                                    Text(
                                      'Segera tangani tiket yang masuk',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: cs.onSurface.withOpacity(
                                              0.55,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // -- Recent Tickets --
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: isAdminOrHelpdesk
                            ? 'Tiket Terbaru'
                            : 'Tiket Terakhir Saya',
                        onTap: () {
                          // TODO: navigate ke ticket list
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TicketListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      if (data.recentTickets.isEmpty)
                        _EmptyState(isAdmin: isAdminOrHelpdesk)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: data.recentTickets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => RecentTicketCard(
                            ticket: data.recentTickets[i],
                            showAssignee: isAdminOrHelpdesk,
                            onTap: () {
                              // TODO: navigate ke ticket detail
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketDetailScreen(
                                      ticketId: data.recentTickets[i].id),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // FAB hanya untuk user biasa
      floatingActionButton: !isAdminOrHelpdesk
          ? FloatingActionButton.extended(
              onPressed: () {
                // Tambahkan baris navigasi ini:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTicketScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.wrnBtsPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Buat Tiket'),
            )
          : null,
    );
  }
}

// -- Internal widgets --

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Lihat Semua',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text('Gagal memuat data', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isAdmin;
  const _EmptyState({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: cs.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            isAdmin ? 'Belum ada tiket masuk' : 'Kamu belum punya tiket',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
