import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// -- Filter State --

enum TicketFilter { all, open, inProgress, resolved, closed }

extension TicketFilterLabel on TicketFilter {
  String get label {
    switch (this) {
      case TicketFilter.all:
        return 'Semua';
      case TicketFilter.open:
        return 'Open';
      case TicketFilter.inProgress:
        return 'In Progress';
      case TicketFilter.resolved:
        return 'Selesai';
      case TicketFilter.closed:
        return 'Closed';
    }
  }

  String? get apiValue {
    switch (this) {
      case TicketFilter.all:
        return null;
      case TicketFilter.open:
        return 'open';
      case TicketFilter.inProgress:
        return 'in_progress';
      case TicketFilter.resolved:
        return 'resolved';
      case TicketFilter.closed:
        return 'closed';
    }
  }
}

// -- Pagination State --

class TicketListState {
  final List<Ticket> tickets;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingPage;
  final String? error;
  final TicketFilter activeFilter;

  const TicketListState({
    this.tickets = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingPage = false,
    this.error,
    this.activeFilter = TicketFilter.all,
  });

  bool get hasPrev => currentPage > 1;
  bool get hasNext => currentPage < totalPages;

  TicketListState copyWith({
    List<Ticket>? tickets,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingPage,
    String? error,
    TicketFilter? activeFilter,
  }) {
    return TicketListState(
      tickets: tickets ?? this.tickets,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingPage: isLoadingPage ?? this.isLoadingPage,
      error: error,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

// -- Notifier --

class TicketListNotifier extends Notifier<TicketListState> {
  final _supabase = Supabase.instance.client;
  static const int _perPage = 8;

  @override
  TicketListState build() {
    Future.microtask(() => fetchTickets());
    return const TicketListState();
  }

  Future<void> fetchTickets({int page = 1, TicketFilter? filter}) async {
    final activeFilter = filter ?? state.activeFilter;

    state = state.copyWith(
      isLoading: page == 1,
      isLoadingPage: page != 1,
      activeFilter: activeFilter,
      error: null,
    );

    try {
      final authState = ref.read(authProvider);
      final currentUserId = _supabase.auth.currentUser?.id;

      var query = _supabase
          .from('tickets')
          .select(
            'id, title, description, status, created_at, '
            'assignee:users!tickets_assignee_id_fkey(name)',
          );

      // Filter berdasarkan status (chip filter)
      if (activeFilter.apiValue != null) {
        query = query.eq('status', activeFilter.apiValue!);
      }

      // Filter berdasarkan role:
      // - user     → hanya tiket milik sendiri (user_id)
      // - helpdesk → hanya tiket yang di-assign ke dia (assignee_id)
      // - admin    → semua tiket tanpa filter tambahan
      if (authState.role == 'user' && currentUserId != null) {
        query = query.eq('user_id', currentUserId);
      } else if (authState.role == 'helpdesk' && currentUserId != null) {
        query = query.eq('assignee_id', currentUserId);
      }

      final start = (page - 1) * _perPage;
      final end = start + _perPage - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(start, end)
          .count(CountOption.exact);

      final count = response.count;
      final totalPages = (count / _perPage).ceil().clamp(1, 999);

      final List<dynamic> data = response.data;
      final List<Ticket> loadedTickets = data.map((row) {
        return Ticket(
          id: row['id'].toString(),
          title: row['title'] ?? 'Tanpa Judul',
          description: row['description'] ?? '',
          status: row['status'] ?? 'open',
          createdAt: row['created_at'].toString().substring(0, 10),
          assigneeName: row['assignee']?['name'],
        );
      }).toList();

      state = state.copyWith(
        tickets: loadedTickets,
        currentPage: page,
        totalPages: totalPages,
        isLoading: false,
        isLoadingPage: false,
      );
    } catch (e) {
      print('Error memuat tiket: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingPage: false,
        error: 'Gagal memuat tiket. Coba lagi.',
      );
    }
  }

  Future<void> setFilter(TicketFilter filter) async {
    if (filter == state.activeFilter) return;
    await fetchTickets(page: 1, filter: filter);
  }

  Future<void> nextPage() async {
    if (!state.hasNext || state.isLoadingPage) return;
    await fetchTickets(page: state.currentPage + 1);
  }

  Future<void> prevPage() async {
    if (!state.hasPrev || state.isLoadingPage) return;
    await fetchTickets(page: state.currentPage - 1);
  }

  Future<void> refresh() async {
    await fetchTickets(page: 1);
  }
}

// -- Provider --

final ticketListProvider =
    NotifierProvider<TicketListNotifier, TicketListState>(
      () => TicketListNotifier(),
    );
