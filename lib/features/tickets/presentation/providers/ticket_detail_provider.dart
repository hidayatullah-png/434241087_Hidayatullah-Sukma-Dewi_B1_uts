import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/date_formatter.dart';

// -- Helpdesk Agents --

class HelpdeskAgent {
  final String id;
  final String name;
  final String role;

  const HelpdeskAgent({
    required this.id,
    required this.name,
    required this.role,
  });
}

// -- Models --

class TicketComment {
  final String id;
  final String authorName;
  final String authorRole;
  final String message;
  final String createdAt;

  const TicketComment({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.message,
    required this.createdAt,
  });
}

class TicketDetail {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String createdAt;
  final String reporterName;
  final String? assigneeName;
  final List<String> attachmentUrls;
  final List<TicketComment> comments;

  const TicketDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.reporterName,
    this.assigneeName,
    this.attachmentUrls = const [],
    this.comments = const [],
  });
}

// -- State --

class TicketDetailState {
  final TicketDetail? ticket;
  final bool isLoading;
  final bool isSubmittingComment;
  final bool isUpdatingStatus;
  final bool isAssigning;
  final String? error;
  final String commentText;
  final List<HelpdeskAgent> availableAgents;

  const TicketDetailState({
    this.ticket,
    this.isLoading = false,
    this.isSubmittingComment = false,
    this.isUpdatingStatus = false,
    this.isAssigning = false,
    this.error,
    this.commentText = '',
    this.availableAgents = const [],
  });

  TicketDetailState copyWith({
    TicketDetail? ticket,
    bool? isLoading,
    bool? isSubmittingComment,
    bool? isUpdatingStatus,
    bool? isAssigning,
    String? error,
    String? commentText,
    List<HelpdeskAgent>? availableAgents,
  }) {
    return TicketDetailState(
      ticket: ticket ?? this.ticket,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isAssigning: isAssigning ?? this.isAssigning,
      error: error,
      commentText: commentText ?? this.commentText,
      availableAgents: availableAgents ?? this.availableAgents,
    );
  }
}

// -- Notifier --

class TicketDetailNotifier extends StateNotifier<TicketDetailState> {
  final String ticketId;
  final _supabase = Supabase.instance.client;

  TicketDetailNotifier(this.ticketId) : super(const TicketDetailState()) {
    fetchDetail();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, role')
          .inFilter('role', ['admin', 'helpdesk']);

      final agents = (response as List).map((data) {
        return HelpdeskAgent(
          id: data['id'].toString(),
          name: data['name'],
          role: data['role'],
        );
      }).toList();

      state = state.copyWith(availableAgents: agents);
    } catch (e) {
      print('Gagal mengambil daftar agent: $e');
    }
  }

  Future<void> fetchDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase
          .from('tickets')
          .select('''
            id, title, description, status, priority, category, created_at,
            reporter:user_id(name),
            assignee:assignee_id(name)
          ''')
          .eq('id', ticketId)
          .single();

      final commentsResponse = await _supabase
          .from('ticket_comments')
          .select('id, message, created_at, users(name, role)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      final List<TicketComment> loadedComments = (commentsResponse as List).map(
        (c) {
          return TicketComment(
            id: c['id'].toString(),
            authorName: c['users']['name'] ?? 'User tidak diketahui',
            authorRole: c['users']['role'] ?? 'user',
            message: c['message'],
            createdAt: DateFormatter.formatDateTime(c['created_at'].toString()),
          );
        },
      ).toList();

      state = state.copyWith(
        isLoading: false,
        ticket: TicketDetail(
          id: response['id'].toString(),
          title: response['title'] ?? 'Tanpa Judul',
          description: response['description'] ?? '',
          status: response['status'] ?? 'open',
          priority: response['priority'] ?? 'medium',
          category: response['category'] ?? 'other',
          createdAt: DateFormatter.formatDateTime(
            response['created_at'].toString(),
          ),
          reporterName: response['reporter']?['name'] ?? 'Unknown',
          assigneeName: response['assignee']?['name'],
          attachmentUrls: const [],
          comments: loadedComments,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat detail tiket: $e',
      );
    }
  }

  void setCommentText(String value) =>
      state = state.copyWith(commentText: value);

  Future<void> submitComment(String authorName, String authorRole) async {
    final text = state.commentText.trim();
    if (text.isEmpty || state.isSubmittingComment || state.ticket == null)
      return;

    state = state.copyWith(isSubmittingComment: true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('ticket_comments')
          .insert({'ticket_id': ticketId, 'user_id': userId, 'message': text})
          .select('id, created_at')
          .single();

      final newComment = TicketComment(
        id: response['id'].toString(),
        authorName: authorName,
        authorRole: authorRole,
        message: text,
        createdAt: DateFormatter.formatDateTime(
          response['created_at'].toString(),
        ),
      );

      state = state.copyWith(
        isSubmittingComment: false,
        commentText: '',
        ticket: _rebuildTicket(
          comments: [...state.ticket!.comments, newComment],
        ),
      );
    } catch (e) {
      print('Gagal kirim komentar: $e');
      state = state.copyWith(isSubmittingComment: false);
    }
  }

  // Admin assign helpdesk → status otomatis jadi in_progress
  Future<void> assignTicket(HelpdeskAgent agent) async {
    if (state.isAssigning || state.ticket == null) return;
    state = state.copyWith(isAssigning: true);

    final isUnassign = agent.id.isEmpty;

    try {
      await _supabase
          .from('tickets')
          .update({
            'assignee_id': isUnassign ? null : agent.id,
            // Otomatis ubah status sesuai alur
            'status': isUnassign ? 'open' : 'in_progress',
          })
          .eq('id', ticketId);

      state = state.copyWith(
        isAssigning: false,
        ticket: _rebuildTicket(
          status: isUnassign ? 'open' : 'in_progress',
          assigneeName: isUnassign ? null : agent.name,
          clearAssignee: isUnassign,
        ),
      );
    } catch (e) {
      print('Gagal menugaskan tiket: $e');
      state = state.copyWith(isAssigning: false);
    }
  }

  // Helpdesk klik Finish → status jadi closed
  Future<void> finishTicket() async {
    await _updateStatus('closed');
  }

  // Dipanggil dari UI (bottom sheet update status admin/helpdesk)
  Future<void> updateStatus(String newStatus) async {
    await _updateStatus(newStatus);
  }

  Future<void> _updateStatus(String newStatus) async {
    if (state.isUpdatingStatus || state.ticket == null) return;
    state = state.copyWith(isUpdatingStatus: true);

    try {
      await _supabase
          .from('tickets')
          .update({'status': newStatus})
          .eq('id', ticketId);

      state = state.copyWith(
        isUpdatingStatus: false,
        ticket: _rebuildTicket(status: newStatus),
      );
    } catch (e) {
      print('Gagal update status: $e');
      state = state.copyWith(isUpdatingStatus: false);
    }
  }

  // Helper rebuild TicketDetail tanpa duplikasi kode
  TicketDetail _rebuildTicket({
    String? status,
    String? assigneeName,
    bool clearAssignee = false,
    List<TicketComment>? comments,
  }) {
    final t = state.ticket!;
    return TicketDetail(
      id: t.id,
      title: t.title,
      description: t.description,
      status: status ?? t.status,
      priority: t.priority,
      category: t.category,
      createdAt: t.createdAt,
      reporterName: t.reporterName,
      assigneeName: clearAssignee ? null : (assigneeName ?? t.assigneeName),
      attachmentUrls: t.attachmentUrls,
      comments: comments ?? t.comments,
    );
  }
}

// -- Provider --

final ticketDetailProvider = StateNotifierProvider.autoDispose
    .family<TicketDetailNotifier, TicketDetailState, String>(
      (ref, ticketId) => TicketDetailNotifier(ticketId),
    );
