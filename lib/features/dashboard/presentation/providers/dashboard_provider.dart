import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/ticket.dart';

// -- Model --

class DashboardData {
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final int unassignedTickets;
  final int unreadNotifications;
  final List<Ticket> recentTickets;

  const DashboardData({
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.unassignedTickets,
    required this.unreadNotifications,
    required this.recentTickets,
  });
}

// -- Repository --

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData();
}

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData() async {
    // TODO: ganti dengan actual HTTP call ke API kamu
    // final res = await http.get(Uri.parse('$baseUrl/api/dashboard'));
    // return DashboardData.fromJson(jsonDecode(res.body));

    await Future.delayed(const Duration(milliseconds: 700));

    return DashboardData(
      totalTickets: 24,
      openTickets: 8,
      inProgressTickets: 5,
      resolvedTickets: 11,
      unassignedTickets: 3,
      unreadNotifications: 2,
      recentTickets: const [
        Ticket(
          id: '1024',
          title: 'Printer lantai 3 tidak bisa digunakan',
          description: 'Printer menampilkan error code 0x03 saat mencetak',
          status: 'open',
          createdAt: '2 jam lalu',
          assigneeName: null,
        ),
        Ticket(
          id: '1023',
          title: 'Akses VPN tidak bisa login',
          description: 'Muncul pesan Authentication Failed saat connect',
          status: 'in_progress',
          createdAt: '5 jam lalu',
          assigneeName: 'Leon K.',
        ),
        Ticket(
          id: '1022',
          title: 'Email tidak bisa kirim attachment',
          description: 'Error saat upload file lebih dari 5MB',
          status: 'resolved',
          createdAt: '1 hari lalu',
          assigneeName: 'Annisa P.',
        ),
      ],
    );
  }
}

// -- Providers --

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(),
);

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboardData();
});
