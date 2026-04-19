// lib/features/tickets/presentation/screens/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_detail_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -- Update Status (admin/helpdesk) --

  void _showUpdateStatusSheet(TicketDetail ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = ['open', 'in_progress', 'resolved', 'closed'];

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
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  'Update Status Tiket',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...statuses.map((s) {
                final style = _statusStyle(s);
                final isCurrent = s == ticket.status;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(style.icon, color: style.color, size: 20),
                  ),
                  title: Text(
                    style.label,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? style.color
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: style.color,
                          size: 18,
                        )
                      : null,
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pop(context);
                          ref
                              .read(
                                ticketDetailProvider(widget.ticketId).notifier,
                              )
                              .updateStatus(s);
                        },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignSheet(TicketDetail ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

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
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  'Assign ke Helpdesk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Opsi unassign
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                title: const Text('Unassign'),
                subtitle: Text(
                  'Hapus penugasan saat ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                onTap: ticket.assigneeName == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        ref
                            .read(
                              ticketDetailProvider(widget.ticketId).notifier,
                            )
                            .assignTicket(
                              const HelpdeskAgent(id: '', name: '', role: ''),
                            );
                      },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ...dummyAgents.map((agent) {
                final isCurrent = agent.name == ticket.assigneeName;
                final roleColor = agent.role == 'admin'
                    ? AppColors.wrnShapeRose
                    : AppColors.wrnLightPurple;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: roleColor.withOpacity(0.15),
                    child: Text(
                      agent.name[0].toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    agent.name,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? roleColor : cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    agent.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: roleColor.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: roleColor,
                          size: 18,
                        )
                      : null,
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pop(context);
                          ref
                              .read(
                                ticketDetailProvider(widget.ticketId).notifier,
                              )
                              .assignTicket(agent);
                        },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // -- Submit comment -- //

  Future<void> _handleSendComment() async {
    final auth = ref.read(authProvider);
    await ref
        .read(ticketDetailProvider(widget.ticketId).notifier)
        .submitComment(auth.name, auth.role);
    _commentController.clear();

    // scroll ke bawah setelah komentar terkirim
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // -- Build -- //

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(ticketDetailProvider(widget.ticketId));
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isAdminOrHelpdesk = auth.role == 'admin' || auth.role == 'helpdesk';

    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.ticketId}'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        // Update status button — admin/helpdesk only
        actions: [
          if (isAdminOrHelpdesk && detailState.ticket != null)
            detailState.isUpdatingStatus
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () =>
                        _showUpdateStatusSheet(detailState.ticket!),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.wrnLightPurple,
                    ),
                  ),
          // Assign button
          if (isAdminOrHelpdesk && detailState.ticket != null)
            detailState.isAssigning
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => _showAssignSheet(detailState.ticket!),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Assign'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.wrnLightPurple,
                    ),
                  ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.wrnLightPurple,
          unselectedLabelColor: cs.onSurface.withOpacity(0.45),
          indicatorColor: AppColors.wrnBtsPurple,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Detail'),
            Tab(text: 'Komentar'),
          ],
        ),
      ),

      body: detailState.isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : detailState.error != null
          ? _ErrorState(
              message: detailState.error!,
              onRetry: () => ref
                  .read(ticketDetailProvider(widget.ticketId).notifier)
                  .fetchDetail(),
            )
          : detailState.ticket == null
          ? const SizedBox()
          : TabBarView(
              controller: _tabController,
              children: [
                // -- Tab 1: Detail -- //
                _DetailTab(
                  ticket: detailState.ticket!,
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                ),

                // -- Tab 2: Komentar -- //
                _CommentTab(
                  ticket: detailState.ticket!,
                  auth: auth,
                  commentController: _commentController,
                  scrollController: _scrollController,
                  detailState: detailState,
                  onCommentChanged: (v) => ref
                      .read(ticketDetailProvider(widget.ticketId).notifier)
                      .setCommentText(v),
                  onSend: _handleSendComment,
                  isDark: isDark,
                  cs: cs,
                  theme: theme,
                ),
              ],
            ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return _StatusStyle(
          label: 'Open',
          color: AppColors.wrnShapeRose,
          icon: Icons.inbox_outlined,
        );
      case 'in_progress':
        return _StatusStyle(
          label: 'In Progress',
          color: AppColors.wrnBtsPurple,
          icon: Icons.autorenew_rounded,
        );
      case 'resolved':
        return _StatusStyle(
          label: 'Selesai',
          color: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline,
        );
      case 'closed':
        return _StatusStyle(
          label: 'Closed',
          color: const Color(0xFF9E9E9E),
          icon: Icons.cancel_outlined,
        );
      default:
        return _StatusStyle(
          label: status,
          color: AppColors.wrnLightPurple,
          icon: Icons.circle_outlined,
        );
    }
  }
}

// -- Tab Detail -- //

class _DetailTab extends StatelessWidget {
  final TicketDetail ticket;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;

  const _DetailTab({
    required this.ticket,
    required this.isDark,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus(ticket.status);
    final priority = _resolvePriority(ticket.priority);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Status + Priority badges -- //
          Row(
            children: [
              _Badge(
                label: status.label,
                color: status.color,
                icon: status.icon,
              ),
              const SizedBox(width: 8),
              _Badge(
                label: priority.label,
                color: priority.color,
                icon: priority.icon,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // -- Judul -- //
          Text(
            ticket.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // -- Info grid -- //
          _InfoCard(
            isDark: isDark,
            cs: cs,
            theme: theme,
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Pelapor',
                value: ticket.reporterName,
              ),
              _InfoRow(
                icon: Icons.support_agent_outlined,
                label: 'Ditangani',
                value: ticket.assigneeName ?? 'Belum di-assign',
              ),
              _InfoRow(
                icon: Icons.category_outlined,
                label: 'Kategori',
                value: ticket.category,
              ),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Dibuat',
                value: ticket.createdAt,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // -- Deskripsi -- //
          Text(
            'Deskripsi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.wrnDarkInput : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.wrnShapePurple.withOpacity(0.25)
                    : cs.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Text(
              ticket.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),

          // -- Attachments -- //
          if (ticket.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Lampiran',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ticket.attachmentUrls.map((url) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.wrnDarkInput
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  _StatusStyle _resolveStatus(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return _StatusStyle(
          label: 'Open',
          color: AppColors.wrnShapeRose,
          icon: Icons.inbox_outlined,
        );
      case 'in_progress':
        return _StatusStyle(
          label: 'In Progress',
          color: AppColors.wrnBtsPurple,
          icon: Icons.autorenew_rounded,
        );
      case 'resolved':
        return _StatusStyle(
          label: 'Selesai',
          color: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline,
        );
      default:
        return _StatusStyle(
          label: 'Closed',
          color: const Color(0xFF9E9E9E),
          icon: Icons.cancel_outlined,
        );
    }
  }

  _StatusStyle _resolvePriority(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return _StatusStyle(
          label: 'Prioritas Tinggi',
          color: AppColors.wrnShapeRose,
          icon: Icons.arrow_upward_rounded,
        );
      case 'low':
        return _StatusStyle(
          label: 'Prioritas Rendah',
          color: const Color(0xFF4CAF50),
          icon: Icons.arrow_downward_rounded,
        );
      default:
        return _StatusStyle(
          label: 'Prioritas Sedang',
          color: AppColors.wrnBtsPurple,
          icon: Icons.remove_rounded,
        );
    }
  }
}

// -- Tab Komentar -- //

class _CommentTab extends StatelessWidget {
  final TicketDetail ticket;
  final AuthState auth;
  final TextEditingController commentController;
  final ScrollController scrollController;
  final TicketDetailState detailState;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onSend;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;

  const _CommentTab({
    required this.ticket,
    required this.auth,
    required this.commentController,
    required this.scrollController,
    required this.detailState,
    required this.onCommentChanged,
    required this.onSend,
    required this.isDark,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // -- Daftar komentar -- //
        Expanded(
          child: ticket.comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: cs.onSurface.withOpacity(0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada komentar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: ticket.comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final comment = ticket.comments[i];
                    final isMe = comment.authorName == auth.name;
                    return _CommentBubble(
                      comment: comment,
                      isMe: isMe,
                      isDark: isDark,
                      cs: cs,
                      theme: theme,
                    );
                  },
                ),
        ),

        // -- Input komentar -- //
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.wrnBtsPurple.withOpacity(0.15),
                  child: Text(
                    auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.wrnBtsPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // TextField
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.wrnDarkBg
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? AppColors.wrnShapePurple.withOpacity(0.25)
                            : cs.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: TextField(
                      controller: commentController,
                      onChanged: onCommentChanged,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(color: cs.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.35),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: detailState.isSubmittingComment ? null : onSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: detailState.commentText.trim().isNotEmpty
                          ? AppColors.wrnBtsPurple
                          : cs.onSurface.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: detailState.isSubmittingComment
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: detailState.commentText.trim().isNotEmpty
                                ? Colors.white
                                : cs.onSurface.withOpacity(0.3),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -- Comment Bubble -- //

class _CommentBubble extends StatelessWidget {
  final TicketComment comment;
  final bool isMe;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;

  const _CommentBubble({
    required this.comment,
    required this.isMe,
    required this.isDark,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? AppColors.wrnBtsPurple
        : isDark
        ? AppColors.wrnDarkInput
        : cs.surfaceContainerLow;
    final textColor = isMe ? Colors.white : cs.onSurface;
    final subColor = isMe
        ? Colors.white.withOpacity(0.65)
        : cs.onSurface.withOpacity(0.45);

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar (hanya untuk orang lain)
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: _roleColor(comment.authorRole).withOpacity(0.15),
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: _roleColor(comment.authorRole),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Bubble
        Flexible(
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Nama + role badge
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        comment.authorName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor(
                            comment.authorRole,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          comment.authorRole.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _roleColor(comment.authorRole),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bubble message
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.wrnShapePurple.withOpacity(0.2)
                              : cs.outlineVariant.withOpacity(0.35),
                        ),
                ),
                child: Text(
                  comment.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    height: 1.45,
                  ),
                ),
              ),

              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  comment.createdAt,
                  style: TextStyle(fontSize: 10, color: subColor),
                ),
              ),
            ],
          ),
        ),

        // Avatar untuk diri sendiri
        if (isMe) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.wrnBtsPurple.withOpacity(0.2),
            child: const Icon(
              Icons.person,
              size: 16,
              color: AppColors.wrnBtsPurple,
            ),
          ),
        ],
      ],
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.wrnShapeRose;
      case 'helpdesk':
        return AppColors.wrnLightPurple;
      default:
        return AppColors.wrnBtsPurple;
    }
  }
}

// -- Reusable Widgets -- //

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final ColorScheme cs;
  final ThemeData theme;

  const _InfoCard({
    required this.children,
    required this.isDark,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrnDarkInput : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.wrnShapePurple.withOpacity(0.25)
              : cs.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: children
            .expand((w) => [w, const Divider(height: 16, thickness: 0.5)])
            .take(children.length * 2 - 1)
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.4)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}

// -- Error State -- //

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

// -- Internal model helpers -- //

class _StatusStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.icon,
  });
}
