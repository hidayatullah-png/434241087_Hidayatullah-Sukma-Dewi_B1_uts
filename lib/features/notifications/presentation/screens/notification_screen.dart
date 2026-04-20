import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifikasi'),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.wrnBtsPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: false,
        actions: [
          // Mark all as read
          if (state.unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllAsRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  color: AppColors.wrnLightPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),

      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : state.error != null
              ? _ErrorState(
                  message: state.error!,
                  onRetry: notifier.refresh,
                )
              : state.notifications.isEmpty
                  ? _EmptyState(cs: cs, theme: theme)
                  : RefreshIndicator(
                      color: cs.primary,
                      onRefresh: notifier.refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 70,
                          color: isDark
                              ? AppColors.wrnShapePurple.withOpacity(0.2)
                              : cs.outlineVariant.withOpacity(0.3),
                        ),
                        itemBuilder: (context, i) {
                          final notif = state.notifications[i];
                          return _NotificationTile(
                            notification: notif,
                            isDark: isDark,
                            cs: cs,
                            theme: theme,
                            onTap: () {
                              notifier.markAsRead(notif.id);
                              // Navigate ke detail tiket
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketDetailScreen(
                                    ticketId: notif.ticketId,
                                  ),
                                ),
                              );
                            },
                            onDismissed: () =>
                                notifier.deleteNotification(notif.id),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Notification Tile ──────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.cs,
    required this.theme,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFCF6679).withOpacity(0.85),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread
              ? AppColors.wrnBtsPurple.withOpacity(isDark ? 0.07 : 0.04)
              : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),

              const SizedBox(width: 12),

              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + unread dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.wrnBtsPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Waktu + tiket badge
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: cs.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          notification.createdAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: style.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${notification.ticketId}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: style.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 16, color: cs.onSurface.withOpacity(0.25)),
            ],
          ),
        ),
      ),
    );
  }

  _NotifStyle _resolveStyle(NotificationType type) {
    switch (type) {
      case NotificationType.statusUpdate:
        return _NotifStyle(
          icon: Icons.autorenew_rounded,
          color: AppColors.wrnBtsPurple,
        );
      case NotificationType.newComment:
        return _NotifStyle(
          icon: Icons.chat_bubble_outline_rounded,
          color: AppColors.wrnLightPurple,
        );
      case NotificationType.assigned:
        return _NotifStyle(
          icon: Icons.person_add_outlined,
          color: AppColors.wrnShapeRose,
        );
      case NotificationType.newTicket:
        return _NotifStyle(
          icon: Icons.confirmation_number_outlined,
          color: const Color(0xFF4CAF50),
        );
    }
  }
}

// ── Helper model ───────────────────────────────────────────────

class _NotifStyle {
  final IconData icon;
  final Color color;
  const _NotifStyle({required this.icon, required this.color});
}

// ── Empty & Error States ───────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  const _EmptyState({required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: cs.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kamu sudah up to date!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(
              onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}