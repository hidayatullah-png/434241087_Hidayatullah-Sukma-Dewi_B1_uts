// lib/features/tickets/presentation/screens/tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/tracking_provider.dart';
import 'ticket_detail_screen.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingProvider);
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    String subtitle;
    switch (auth.role) {
      case 'helpdesk':
        subtitle = 'Tiket yang sedang kamu tangani';
        break;
      case 'admin':
        subtitle = 'Semua tiket yang belum selesai';
        break;
      default:
        subtitle = 'Tiket aktif kamu';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading
                ? null
                : () => ref.read(trackingProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : state.error != null
          ? _ErrorState(
              message: state.error!,
              onRetry: () => ref.read(trackingProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              color: cs.primary,
              onRefresh: () => ref.read(trackingProvider.notifier).refresh(),
              child: state.tickets.isEmpty
                  ? _EmptyState(role: auth.role)
                  : CustomScrollView(
                      slivers: [
                        // Subtitle
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: cs.onSurface.withOpacity(0.4),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${state.tickets.length} tiket',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.wrnLightPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List tiket
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final ticket = state.tickets[i];
                              final isExpanded =
                                  state.expandedTicketId == ticket.ticketId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TicketTrackingCard(
                                  ticket: ticket,
                                  isExpanded: isExpanded,
                                  isDark: isDark,
                                  cs: cs,
                                  theme: theme,
                                  onToggle: () => ref
                                      .read(trackingProvider.notifier)
                                      .toggleExpand(ticket.ticketId),
                                  onViewDetail: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TicketDetailScreen(
                                        ticketId: ticket.ticketId,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: state.tickets.length),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

// ── Ticket Tracking Card ───────────────────────────────────────

class _TicketTrackingCard extends StatelessWidget {
  final TicketTrackingItem ticket;
  final bool isExpanded;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onToggle;
  final VoidCallback onViewDetail;

  const _TicketTrackingCard({
    required this.ticket,
    required this.isExpanded,
    required this.isDark,
    required this.cs,
    required this.theme,
    required this.onToggle,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _resolveStatus(ticket.currentStatus);
    final priorityColor = _priorityColor(ticket.priority);

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
      child: Column(
        children: [
          // ── Header ──
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Priority
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusStyle.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusStyle.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusStyle.icon,
                              size: 11,
                              color: statusStyle.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusStyle.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusStyle.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                      const Spacer(),
                      // Expand chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Judul
                  Text(
                    ticket.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Info baris bawah
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.reporterName,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (ticket.assigneeName != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.support_agent_outlined,
                          size: 12,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.assigneeName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        ticket.createdAt,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Timeline (expandable) ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.wrnShapePurple.withOpacity(0.2)
                      : cs.outlineVariant.withOpacity(0.3),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        'Riwayat Status',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _VerticalTimeline(
                  entries: ticket.history,
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                ),
                // Tombol lihat detail
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onViewDetail,
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Lihat Detail Tiket'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.wrnLightPurple,
                        side: BorderSide(
                          color: AppColors.wrnLightPurple.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  _StatusStyle _resolveStatus(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return _StatusStyle(
          'Open',
          AppColors.wrnShapeRose,
          Icons.inbox_outlined,
        );
      case 'in_progress':
        return _StatusStyle(
          'In Progress',
          AppColors.wrnBtsPurple,
          Icons.autorenew_rounded,
        );
      case 'resolved':
        return _StatusStyle(
          'Selesai',
          const Color(0xFF4CAF50),
          Icons.check_circle_outline,
        );
      case 'closed':
        return _StatusStyle(
          'Closed',
          const Color(0xFF9E9E9E),
          Icons.cancel_outlined,
        );
      default:
        return _StatusStyle(s, AppColors.wrnLightPurple, Icons.circle_outlined);
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return AppColors.wrnShapeRose;
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.wrnBtsPurple;
    }
  }
}

// ── Vertical Timeline ──────────────────────────────────────────

class _VerticalTimeline extends StatelessWidget {
  final List<TicketHistoryEntry> entries;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;

  const _VerticalTimeline({
    required this.entries,
    required this.isDark,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(entries.length, (i) {
          final entry = entries[i];
          final isLast = i == entries.length - 1;
          final statusStyle = _resolveStatus(entry.newStatus);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Garis + Dot ──
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      // Dot
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: statusStyle.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusStyle.color,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          statusStyle.icon,
                          size: 13,
                          color: statusStyle.color,
                        ),
                      ),
                      // Garis vertikal
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isDark
                                ? AppColors.wrnShapePurple.withOpacity(0.3)
                                : cs.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Konten ──
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 8 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status label
                        Row(
                          children: [
                            Text(
                              statusStyle.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: statusStyle.color,
                              ),
                            ),
                            if (entry.oldStatus != null) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: cs.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _resolveStatus(entry.oldStatus!).label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.4),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Note
                        if (entry.note != null && entry.note!.isNotEmpty)
                          Text(
                            entry.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),

                        const SizedBox(height: 4),

                        // By + waktu
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 11,
                              color: cs.onSurface.withOpacity(0.35),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              entry.changedBy,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.45),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: cs.onSurface.withOpacity(0.35),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              entry.createdAt,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  _StatusStyle _resolveStatus(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return _StatusStyle(
          'Open',
          AppColors.wrnShapeRose,
          Icons.inbox_outlined,
        );
      case 'in_progress':
        return _StatusStyle(
          'In Progress',
          AppColors.wrnBtsPurple,
          Icons.autorenew_rounded,
        );
      case 'resolved':
        return _StatusStyle(
          'Selesai',
          const Color(0xFF4CAF50),
          Icons.check_circle_outline,
        );
      case 'closed':
        return _StatusStyle(
          'Closed',
          const Color(0xFF9E9E9E),
          Icons.cancel_outlined,
        );
      default:
        return _StatusStyle(s, AppColors.wrnLightPurple, Icons.circle_outlined);
    }
  }
}

// ── Empty & Error States ───────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String role;
  const _EmptyState({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final message = role == 'user'
        ? 'Tidak ada tiket aktif saat ini'
        : role == 'helpdesk'
        ? 'Tidak ada tiket yang ditugaskan ke kamu'
        : 'Semua tiket sudah selesai';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_rounded,
            size: 64,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tiket yang sudah closed tidak ditampilkan di sini',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
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
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// ── Internal model ─────────────────────────────────────────────

class _StatusStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusStyle(this.label, this.color, this.icon);
}
