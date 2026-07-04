import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_formatter.dart';


// ── Models ─────────────────────────────────────────────────────

class TicketTrackingItem {
  final String ticketId;
  final String title;
  final String currentStatus;
  final String priority;
  final String category;
  final String reporterName;
  final String? assigneeName;
  final String createdAt;
  final List<TicketHistoryEntry> history;

  const TicketTrackingItem({
    required this.ticketId,
    required this.title,
    required this.currentStatus,
    required this.priority,
    required this.category,
    required this.reporterName,
    this.assigneeName,
    required this.createdAt,
    required this.history,
  });
}

class TicketHistoryEntry {
  final String id;
  final String? oldStatus;
  final String newStatus;
  final String? note;
  final String changedBy;
  final String createdAt;

  const TicketHistoryEntry({
    required this.id,
    this.oldStatus,
    required this.newStatus,
    this.note,
    required this.changedBy,
    required this.createdAt,
  });
}

// ── State ──────────────────────────────────────────────────────

class TrackingState {
  final List<TicketTrackingItem> tickets;
  final bool isLoading;
  final String? error;
  final String? expandedTicketId; // tiket yang sedang dibuka timelinenya

  const TrackingState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
    this.expandedTicketId,
  });

  TrackingState copyWith({
    List<TicketTrackingItem>? tickets,
    bool? isLoading,
    String? error,
    String? expandedTicketId,
    bool clearExpanded = false,
  }) {
    return TrackingState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      expandedTicketId: clearExpanded
          ? null
          : (expandedTicketId ?? this.expandedTicketId),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────

class TrackingNotifier extends StateNotifier<TrackingState> {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  TrackingNotifier(this.ref) : super(const TrackingState()) {
    fetchTracking();
  }

  Future<void> fetchTracking() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final auth = ref.read(authProvider);
      final userId = _supabase.auth.currentUser?.id;

      // Build query berdasarkan role
      var query = _supabase.from('tickets').select('''
        id, title, status, priority, category, created_at,
        reporter:user_id(name),
        assignee:assignee_id(name)
      ''');

      if (auth.role == 'user') {
        // User: hanya tiket milik sendiri yang belum closed
        query = query.eq('user_id', userId!).neq('status', 'closed');
      } else if (auth.role == 'helpdesk') {
        // Helpdesk: tiket yang di-assign ke dia, belum closed
        query = query.eq('assignee_id', userId!).neq('status', 'closed');
      } else {
        // Admin: semua tiket yang belum closed
        query = query.neq('status', 'closed');
      }

      final ticketRows = await query.order('created_at', ascending: false);

      // Ambil history untuk setiap tiket
      final List<TicketTrackingItem> result = [];
      for (final row in ticketRows as List) {
        final ticketId = row['id'].toString();

        final historyRows = await _supabase
            .from('ticket_history')
            .select('id, old_status, new_status, note, created_at, users(name)')
            .eq('ticket_id', ticketId)
            .order('created_at', ascending: true);

        final history = (historyRows as List).map((h) {
          return TicketHistoryEntry(
            id: h['id'].toString(),
            oldStatus: h['old_status'],
            newStatus: h['new_status'] ?? '',
            note: h['note'],
            changedBy: h['users']?['name'] ?? 'System',
            createdAt: DateFormatter.formatDateTime(h['created_at'].toString()),
          );
        }).toList();

        // Kalau history kosong, buat entry awal dari created_at
        if (history.isEmpty) {
          history.add(
            TicketHistoryEntry(
              id: 'init',
              oldStatus: null,
              newStatus: 'open',
              note: 'Tiket dibuat',
              changedBy: row['reporter']?['name'] ?? 'User',
              createdAt: DateFormatter.formatDateTime(row['created_at'].toString()),
            ),
          );
        }

        result.add(
          TicketTrackingItem(
            ticketId: ticketId,
            title: row['title'] ?? 'Tanpa Judul',
            currentStatus: row['status'] ?? 'open',
            priority: row['priority'] ?? 'medium',
            category: row['category'] ?? '-',
            reporterName: row['reporter']?['name'] ?? 'Unknown',
            assigneeName: row['assignee']?['name'],
            createdAt: DateFormatter.formatDateOnly(row['created_at'].toString()),
            history: history,
          ),
        );
      }

      state = state.copyWith(isLoading: false, tickets: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat tracking: $e',
      );
    }
  }

  void toggleExpand(String ticketId) {
    if (state.expandedTicketId == ticketId) {
      state = state.copyWith(clearExpanded: true);
    } else {
      state = state.copyWith(expandedTicketId: ticketId);
    }
  }

  Future<void> refresh() => fetchTracking();
}

// ── Provider ───────────────────────────────────────────────────

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) => TrackingNotifier(ref),
);
