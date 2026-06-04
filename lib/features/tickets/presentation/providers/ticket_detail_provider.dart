import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -- Helpdesk Agents (Sekarang dinamis dari Database) --

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
  final String authorRole; // 'user' | 'helpdesk' | 'admin'
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
// (SAMA PERSIS)

class TicketDetailState {
  final TicketDetail? ticket;
  final bool isLoading;
  final bool isSubmittingComment;
  final bool isUpdatingStatus;
  final bool isAssigning;
  final String? error;
  final String commentText;

  // Menyimpan daftar agent untuk form Assign
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
    _fetchAgents(); // Ambil list agent (admin & helpdesk) untuk menu assign
  }

  Future<void> _fetchAgents() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, role')
          .inFilter('role', ['admin', 'helpdesk']);

      final agents = response.map((data) {
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
      // 1. Ambil detail tiket (Join tabel users 2 kali: untuk Reporter dan Assignee)
      final response = await _supabase
          .from('tickets')
          .select('''
            id, title, description, status, priority, category, created_at,
            reporter:user_id(name),
            assignee:assignee_id(name)
          ''')
          .eq('id', ticketId)
          .single();

      // 2. Ambil komentar tiket (Join ke tabel users untuk tau siapa yang komentar)
      final commentsResponse = await _supabase
          .from('ticket_comments')
          .select('id, message, created_at, users(name, role)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true); // Urut dari terlama ke terbaru

      final List<TicketComment> loadedComments = commentsResponse.map((c) {
        return TicketComment(
          id: c['id'].toString(),
          authorName: c['users']['name'] ?? 'User tidak diketahui',
          authorRole: c['users']['role'] ?? 'user',
          message: c['message'],
          createdAt: c['created_at'].toString().substring(
            0,
            16,
          ), // Sederhanakan format jam
        );
      }).toList();

      // 3. Masukkan ke dalam State (Ingat: tidak ada perubahan nama properti di Model!)
      state = state.copyWith(
        isLoading: false,
        ticket: TicketDetail(
          id: response['id'].toString(),
          title: response['title'] ?? 'Tanpa Judul',
          description: response['description'] ?? '',
          status: response['status'] ?? 'open',
          priority: response['priority'] ?? 'medium',
          category: response['category'] ?? 'other',
          createdAt: response['created_at'].toString().substring(0, 16),
          reporterName: response['reporter']?['name'] ?? 'Unknown Reporter',
          assigneeName: response['assignee']?['name'],
          attachmentUrls:
              [], // TODO: Nanti bisa ditambah kalau pakai Storage bucket
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

      // Insert ke Supabase
      final response = await _supabase
          .from('ticket_comments')
          .insert({'ticket_id': ticketId, 'user_id': userId, 'message': text})
          .select('id, created_at')
          .single();

      // Tambahkan ke UI Local
      final newComment = TicketComment(
        id: response['id'].toString(),
        authorName: authorName,
        authorRole: authorRole,
        message: text,
        createdAt: response['created_at'].toString().substring(0, 16),
      );

      final updatedComments = [...state.ticket!.comments, newComment];

      // Re-build TicketDetail tanpa merusak atribut lain
      state = state.copyWith(
        isSubmittingComment: false,
        commentText: '',
        ticket: TicketDetail(
          id: state.ticket!.id,
          title: state.ticket!.title,
          description: state.ticket!.description,
          status: state.ticket!.status,
          priority: state.ticket!.priority,
          category: state.ticket!.category,
          createdAt: state.ticket!.createdAt,
          reporterName: state.ticket!.reporterName,
          assigneeName: state.ticket!.assigneeName,
          attachmentUrls: state.ticket!.attachmentUrls,
          comments: updatedComments,
        ),
      );
    } catch (e) {
      print('Gagal kirim komentar: $e');
      state = state.copyWith(isSubmittingComment: false);
    }
  }

  Future<void> updateStatus(String newStatus) async {
    if (state.isUpdatingStatus || state.ticket == null) return;
    state = state.copyWith(isUpdatingStatus: true);

    try {
      // Update di Supabase
      await _supabase
          .from('tickets')
          .update({'status': newStatus})
          .eq('id', ticketId);

      // Update di UI local
      state = state.copyWith(
        isUpdatingStatus: false,
        ticket: TicketDetail(
          id: state.ticket!.id,
          title: state.ticket!.title,
          description: state.ticket!.description,
          status: newStatus,
          priority: state.ticket!.priority,
          category: state.ticket!.category,
          createdAt: state.ticket!.createdAt,
          reporterName: state.ticket!.reporterName,
          assigneeName: state.ticket!.assigneeName,
          attachmentUrls: state.ticket!.attachmentUrls,
          comments: state.ticket!.comments,
        ),
      );
    } catch (e) {
      print('Gagal update status: $e');
      state = state.copyWith(isUpdatingStatus: false);
    }
  }

  Future<void> assignTicket(HelpdeskAgent agent) async {
    if (state.isAssigning || state.ticket == null) return;
    state = state.copyWith(isAssigning: true);

    try {
      // Update di Supabase
      await _supabase
          .from('tickets')
          .update({'assignee_id': agent.id})
          .eq('id', ticketId);

      // Update di UI local
      state = state.copyWith(
        isAssigning: false,
        ticket: TicketDetail(
          id: state.ticket!.id,
          title: state.ticket!.title,
          description: state.ticket!.description,
          status: state.ticket!.status,
          priority: state.ticket!.priority,
          category: state.ticket!.category,
          createdAt: state.ticket!.createdAt,
          reporterName: state.ticket!.reporterName,
          assigneeName: agent.name,
          attachmentUrls: state.ticket!.attachmentUrls,
          comments: state.ticket!.comments,
        ),
      );
    } catch (e) {
      print('Gagal menugaskan tiket: $e');
      state = state.copyWith(isAssigning: false);
    }
  }
}

// -- Provider --

final ticketDetailProvider = StateNotifierProvider.autoDispose
    .family<TicketDetailNotifier, TicketDetailState, String>(
      (ref, ticketId) => TicketDetailNotifier(ticketId),
    );
