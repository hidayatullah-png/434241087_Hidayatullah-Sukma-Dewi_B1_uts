// lib/features/tickets/presentation/providers/ticket_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/ticket.dart';

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

// -- Pagination State ---

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

// -- Notifier ---

class TicketListNotifier extends StateNotifier<TicketListState> {
  TicketListNotifier() : super(const TicketListState()) {
    fetchTickets();
  }

  static const int _perPage = 8;

  Future<void> fetchTickets({int page = 1, TicketFilter? filter}) async {
    final activeFilter = filter ?? state.activeFilter;

    state = state.copyWith(
      isLoading: page == 1,
      isLoadingPage: page != 1,
      activeFilter: activeFilter,
      error: null,
    );

    try {
      // TODO: ganti dengan actual API call
      // final res = await http.get(Uri.parse(
      //   '$baseUrl/api/tickets?page=$page&per_page=$_perPage&status=${activeFilter.apiValue ?? ""}',
      // ));
      // final json = jsonDecode(res.body);

      await Future.delayed(const Duration(milliseconds: 600));

      // -- Mock data --
      final allMock = _generateMockTickets();
      final filtered = activeFilter == TicketFilter.all
          ? allMock
          : allMock.where((t) => t.status == activeFilter.apiValue).toList();

      final totalPages = (filtered.length / _perPage).ceil().clamp(1, 999);
      final start = ((page - 1) * _perPage).clamp(0, filtered.length);
      final end = (page * _perPage).clamp(0, filtered.length);
      final pageItems = filtered.sublist(start, end);

      state = state.copyWith(
        tickets: pageItems,
        currentPage: page,
        totalPages: totalPages,
        isLoading: false,
        isLoadingPage: false,
      );
    } catch (e) {
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

// -- Provider ---

final ticketListProvider =
    StateNotifierProvider<TicketListNotifier, TicketListState>(
      (ref) => TicketListNotifier(),
    );

// -- Mock Data Generator ---

List<Ticket> _generateMockTickets() => [
  const Ticket(
    id: '1024',
    title: 'Printer lantai 3 error',
    description: 'Error code 0x03 saat mencetak dokumen penting',
    status: 'open',
    createdAt: '2 jam lalu',
    assigneeName: null,
  ),
  const Ticket(
    id: '1023',
    title: 'VPN tidak bisa login',
    description: 'Authentication Failed setiap kali mencoba connect',
    status: 'in_progress',
    createdAt: '5 jam lalu',
    assigneeName: 'Leon K.',
  ),
  const Ticket(
    id: '1022',
    title: 'Email tidak bisa kirim attachment',
    description: 'Error upload file lebih dari 5MB',
    status: 'resolved',
    createdAt: '1 hari lalu',
    assigneeName: 'Annisa P.',
  ),
  const Ticket(
    id: '1021',
    title: 'Laptop tidak bisa booting',
    description: 'Layar hitam setelah logo Windows muncul',
    status: 'open',
    createdAt: '1 hari lalu',
    assigneeName: null,
  ),
  const Ticket(
    id: '1020',
    title: 'Akun SSO terkunci',
    description: 'Tidak bisa login ke sistem setelah salah password 3 kali',
    status: 'in_progress',
    createdAt: '2 hari lalu',
    assigneeName: 'Sukma D.',
  ),
  const Ticket(
    id: '1019',
    title: 'Internet lambat di ruang meeting',
    description: 'Kecepatan download hanya 1 Mbps padahal paket 100 Mbps',
    status: 'open',
    createdAt: '2 hari lalu',
    assigneeName: null,
  ),
  const Ticket(
    id: '1018',
    title: 'Software CAD tidak bisa dibuka',
    description: 'Muncul error "License not found" setiap kali launch',
    status: 'resolved',
    createdAt: '3 hari lalu',
    assigneeName: 'Annisa P.',
  ),
  const Ticket(
    id: '1017',
    title: 'Monitor kedap-kedip',
    description: 'Layar berkedip setiap beberapa menit sekali',
    status: 'closed',
    createdAt: '3 hari lalu',
    assigneeName: 'Leon K.',
  ),
  const Ticket(
    id: '1016',
    title: 'Scanner tidak terdeteksi',
    description: 'Driver sudah di-install tapi device tidak muncul',
    status: 'open',
    createdAt: '4 hari lalu',
    assigneeName: null,
  ),
  const Ticket(
    id: '1015',
    title: 'Google Meet tidak bisa share screen',
    description: 'Tombol share screen greyed out di browser Chrome',
    status: 'in_progress',
    createdAt: '4 hari lalu',
    assigneeName: 'Sukma D.',
  ),
  const Ticket(
    id: '1014',
    title: 'Keyboard wireless tidak responsif',
    description: 'Beberapa tombol tidak berfungsi meski baterai baru',
    status: 'resolved',
    createdAt: '5 hari lalu',
    assigneeName: 'Leon K.',
  ),
  const Ticket(
    id: '1013',
    title: 'File server tidak bisa diakses',
    description: 'Network path tidak ditemukan dari semua komputer divisi',
    status: 'closed',
    createdAt: '5 hari lalu',
    assigneeName: 'Annisa P.',
  ),
  const Ticket(
    id: '1012',
    title: 'Antivirus expired',
    description: 'Notifikasi lisensi habis di 5 komputer sekaligus',
    status: 'open',
    createdAt: '6 hari lalu',
    assigneeName: null,
  ),
  const Ticket(
    id: '1011',
    title: 'Proyektor tidak connect HDMI',
    description: 'Sudah coba ganti kabel tapi tetap no signal',
    status: 'resolved',
    createdAt: '1 minggu lalu',
    assigneeName: 'Sukma D.',
  ),
  const Ticket(
    id: '1010',
    title: 'RAM laptop penuh terus',
    description:
        'Task manager menunjukkan 95% RAM usage padahal tidak banyak aplikasi',
    status: 'closed',
    createdAt: '1 minggu lalu',
    assigneeName: 'Leon K.',
  ),
  const Ticket(
    id: '1009',
    title: 'Backup otomatis gagal',
    description: 'Scheduled backup tidak jalan sejak update sistem minggu lalu',
    status: 'in_progress',
    createdAt: '1 minggu lalu',
    assigneeName: 'Annisa P.',
  ),
];
