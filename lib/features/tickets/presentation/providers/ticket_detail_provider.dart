// lib/features/tickets/presentation/providers/ticket_detail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// -- Helpdesk Agents (dummy — ganti dengan API call) --

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

const dummyAgents = [
  HelpdeskAgent(id: 'h1', name: 'Annisa Putri Amalia', role: 'helpdesk'),
  HelpdeskAgent(id: 'h2', name: 'Luis Serra', role: 'helpdesk'),
  HelpdeskAgent(id: 'h3', name: 'Hidayatullah Sukma Dewi', role: 'admin'),
];

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

class TicketDetailState {
  final TicketDetail? ticket;
  final bool isLoading;
  final bool isSubmittingComment;
  final bool isUpdatingStatus;
  final bool isAssigning;
  final String? error;
  final String commentText;

  const TicketDetailState({
    this.ticket,
    this.isLoading = false,
    this.isSubmittingComment = false,
    this.isUpdatingStatus = false,
    this.isAssigning = false,
    this.error,
    this.commentText = '',
  });

  TicketDetailState copyWith({
    TicketDetail? ticket,
    bool? isLoading,
    bool? isSubmittingComment,
    bool? isUpdatingStatus,
    bool? isAssigning,
    String? error,
    String? commentText,
  }) {
    return TicketDetailState(
      ticket: ticket ?? this.ticket,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isAssigning: isAssigning ?? this.isAssigning,
      error: error,
      commentText: commentText ?? this.commentText,
    );
  }
}

// -- Notifier --

class TicketDetailNotifier extends StateNotifier<TicketDetailState> {
  final String ticketId;

  TicketDetailNotifier(this.ticketId) : super(const TicketDetailState()) {
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: ganti dengan actual API call
      // final res = await http.get(Uri.parse('$baseUrl/api/tickets/$ticketId'));
      // final detail = TicketDetail.fromJson(jsonDecode(res.body));

      await Future.delayed(const Duration(milliseconds: 700));

      state = state.copyWith(
        isLoading: false,
        ticket: TicketDetail(
          id: ticketId,
          title: 'Printer lantai 3 tidak bisa digunakan',
          description:
              'Printer di lantai 3 ruang A menampilkan error code 0x03 setiap kali mencoba mencetak dokumen. Sudah dicoba restart namun masalah tetap muncul. Printer ini digunakan oleh seluruh tim divisi keuangan untuk mencetak laporan harian.',
          status: 'in_progress',
          priority: 'high',
          category: 'Hardware',
          createdAt: '19 Apr 2026, 08:30',
          reporterName: 'Leon S. Kennedy',
          assigneeName: 'Annisa Putri Amalia',
          attachmentUrls: [],
          comments: const [
            TicketComment(
              id: '1',
              authorName: 'Leon S. Kennedy',
              authorRole: 'user',
              message:
                  'Sudah coba restart printer tapi masalah tetap ada. Apakah ada solusi?',
              createdAt: '19 Apr 2026, 08:35',
            ),
            TicketComment(
              id: '2',
              authorName: 'Annisa Putri Amalia',
              authorRole: 'helpdesk',
              message:
                  'Terima kasih laporannya. Saya akan cek driver printer dan kondisi hardware-nya. Mohon tunggu ya.',
              createdAt: '19 Apr 2026, 09:10',
            ),
            TicketComment(
              id: '3',
              authorName: 'Leon S. Kennedy',
              authorRole: 'user',
              message: 'Baik, terima kasih. Ditunggu ya kak.',
              createdAt: '19 Apr 2026, 09:15',
            ),
          ],
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat detail tiket.',
      );
    }
  }

  void setCommentText(String value) =>
      state = state.copyWith(commentText: value);

  Future<void> submitComment(String authorName, String authorRole) async {
    final text = state.commentText.trim();
    if (text.isEmpty || state.isSubmittingComment) return;

    state = state.copyWith(isSubmittingComment: true);

    try {
      // TODO: ganti dengan actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      final newComment = TicketComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorName: authorName,
        authorRole: authorRole,
        message: text,
        createdAt: 'Baru saja',
      );

      final updatedComments = [...state.ticket!.comments, newComment];

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
      state = state.copyWith(isSubmittingComment: false);
    }
  }

  Future<void> updateStatus(String newStatus) async {
    if (state.isUpdatingStatus) return;
    state = state.copyWith(isUpdatingStatus: true);

    try {
      // TODO: ganti dengan actual API call
      // await http.patch(Uri.parse('$baseUrl/api/tickets/$ticketId/status'),
      //   body: {'status': newStatus});
      await Future.delayed(const Duration(milliseconds: 600));

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
      state = state.copyWith(isUpdatingStatus: false);
    }
  }

  Future<void> assignTicket(HelpdeskAgent agent) async {
    if (state.isAssigning) return;
    state = state.copyWith(isAssigning: true);

    try {
      // TODO: ganti dengan actual API call
      // await http.patch(Uri.parse('\$baseUrl/api/tickets/\$ticketId/assign'),
      //   body: {'assignee_id': agent.id});
      await Future.delayed(const Duration(milliseconds: 600));

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
      state = state.copyWith(isAssigning: false);
    }
  }
}

// -- Provider --

final ticketDetailProvider = StateNotifierProvider.autoDispose
    .family<TicketDetailNotifier, TicketDetailState, String>(
      (ref, ticketId) => TicketDetailNotifier(ticketId),
    );
