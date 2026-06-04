import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('tickets')
          .select(
            'id, title, description, status, created_at, assignee:users!tickets_assignee_id_fkey(name)',
          )
          .order('created_at', ascending: false);

      // ← Ini yang hilang di kode kamu
      final List<dynamic> rawTickets = response;

      int open = 0;
      int inProgress = 0;
      int resolved = 0;
      int unassigned = 0;
      final List<Ticket> recentList = [];

      for (var row in rawTickets) {
        final status = row['status'] as String;

        if (status == 'open') open++;
        if (status == 'in_progress') inProgress++;
        if (status == 'resolved') resolved++;

        final assigneeName = row['assignee']?['name'];
        if (assigneeName == null) unassigned++;

        if (recentList.length < 3) {
          recentList.add(
            Ticket(
              id: row['id'].toString(),
              title: row['title'] ?? 'Tanpa Judul',
              description: row['description'] ?? '',
              status: status,
              createdAt: row['created_at'].toString().substring(0, 10),
              assigneeName: assigneeName,
            ),
          );
        }
      }

      return DashboardData(
        totalTickets: rawTickets.length,
        openTickets: open,
        inProgressTickets: inProgress,
        resolvedTickets: resolved,
        unassignedTickets: unassigned,
        unreadNotifications: 2,
        recentTickets: recentList,
      );
    } catch (e) {
      print('Dashboard error: $e');
      rethrow;
    }
  }
}

// -- Providers --

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(),
);

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.getDashboardData();
  } catch (e, stack) {
    print('=== DASHBOARD ERROR ===');
    print(e.toString());
    print(stack.toString());
    rethrow;
  }
});
