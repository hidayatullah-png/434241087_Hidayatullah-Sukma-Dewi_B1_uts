import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ticket_list_provider.dart';
import '../widgets/recent_ticket_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(ticketListProvider);
    final notifier = ref.read(ticketListProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isAdminOrHelpdesk = auth.role == 'admin' || auth.role == 'helpdesk';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        centerTitle: false,
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : notifier.refresh,
          ),
          const SizedBox(width: 4),
        ],
        // Filter chips di bottom app bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterChips(
            activeFilter: state.activeFilter,
            onSelected: (f) => notifier.setFilter(f),
            isDark: isDark,
            cs: cs,
          ),
        ),
      ),

      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : state.error != null
          ? _ErrorState(message: state.error!, onRetry: notifier.refresh)
          : state.tickets.isEmpty
          ? _EmptyState(filter: state.activeFilter)
          : Column(
              children: [
                // -- Ticket list --
                Expanded(
                  child: RefreshIndicator(
                    color: cs.primary,
                    onRefresh: notifier.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: state.tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final ticket = state.tickets[i];
                        return RecentTicketCard(
                          ticket: ticket,
                          showAssignee: true,
                          onTap: () {
                            // TODO: navigate ke detail tiket
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TicketDetailScreen(ticketId: ticket.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // -- Pagination bar --
                _PaginationBar(
                  state: state,
                  onPrev: notifier.prevPage,
                  onNext: notifier.nextPage,
                  onJumpPage: (page) => notifier.fetchTickets(page: page),
                  isDark: isDark,
                  cs: cs,
                ),
              ],
            ),

      // FAB buat tiket
      floatingActionButton: !isAdminOrHelpdesk
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: navigate ke create ticket
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

// -- Filter Chips ---

class _FilterChips extends StatelessWidget {
  final TicketFilter activeFilter;
  final ValueChanged<TicketFilter> onSelected;
  final bool isDark;
  final ColorScheme cs;

  const _FilterChips({
    required this.activeFilter,
    required this.onSelected,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: TicketFilter.values.map((filter) {
          final isActive = filter == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.wrnBtsPurple
                      : isDark
                      ? AppColors.wrnDarkInput
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.wrnBtsPurple
                        : isDark
                        ? AppColors.wrnShapePurple.withOpacity(0.3)
                        : cs.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -- Pagination Bar ---

class _PaginationBar extends StatelessWidget {
  final TicketListState state;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onJumpPage;
  final bool isDark;
  final ColorScheme cs;

  const _PaginationBar({
    required this.state,
    required this.onPrev,
    required this.onNext,
    required this.onJumpPage,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrnDarkInput : cs.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.wrnShapePurple.withOpacity(0.2)
                : cs.outlineVariant.withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prev button
          _PageButton(
            icon: Icons.chevron_left,
            label: 'Prev',
            enabled: state.hasPrev && !state.isLoadingPage,
            onTap: onPrev,
            cs: cs,
          ),

          // Page indicator — tap dot untuk jump ke halaman
          state.isLoadingPage
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : Row(
                  children: List.generate(state.totalPages.clamp(0, 5), (i) {
                    final pageNum = i + 1;
                    final isActive = pageNum == state.currentPage;
                    return GestureDetector(
                      onTap: () => onJumpPage(pageNum),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.wrnBtsPurple
                              : cs.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),

          // Next button
          _PageButton(
            icon: Icons.chevron_right,
            label: 'Next',
            iconAfter: true,
            enabled: state.hasNext && !state.isLoadingPage,
            onTap: onNext,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool iconAfter;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _PageButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.cs,
    this.iconAfter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.wrnBtsPurple
        : cs.onSurface.withOpacity(0.25);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          if (!iconAfter) Icon(icon, size: 18, color: color),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (iconAfter) Icon(icon, size: 18, color: color),
        ],
      ),
    );
  }
}

// -- Empty & Error States ---

class _EmptyState extends StatelessWidget {
  final TicketFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: cs.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 16),
          Text(
            filter == TicketFilter.all
                ? 'Belum ada tiket'
                : 'Tidak ada tiket "${filter.label}"',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: cs.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
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
