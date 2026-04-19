import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/ticket.dart';

class RecentTicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool showAssignee;
  final VoidCallback onTap;

  const RecentTicketCard({
    super.key,
    required this.ticket,
    required this.showAssignee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final status = _resolveStatus(ticket.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // dark: wrnDarkInput, light: surface
          color: isDark ? AppColors.wrnDarkInput : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.wrnShapePurple.withOpacity(0.25)
                : cs.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID + Title
                  Row(
                    children: [
                      Text(
                        '#${ticket.id}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    ticket.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Status chip + assignee/date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status.color.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (showAssignee && ticket.assigneeName != null) ...[
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.assigneeName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ] else
                        Text(
                          ticket.createdAt,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyle _resolveStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return _StatusStyle('Open', AppColors.wrnShapeRose);
      case 'in_progress':
        return _StatusStyle('In Progress', AppColors.wrnBtsPurple);
      case 'resolved':
        return _StatusStyle('Selesai', const Color(0xFF4CAF50));
      case 'closed':
        return _StatusStyle('Closed', const Color(0xFF9E9E9E));
      default:
        return _StatusStyle(status, AppColors.wrnLightPurple);
    }
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  const _StatusStyle(this.label, this.color);
}
