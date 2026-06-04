import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model ──────────────────────────────────────────────────────

enum NotificationType { statusUpdate, newComment, assigned, newTicket }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String ticketId;
  final String createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.ticketId,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    ticketId: ticketId,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

// ── State ──────────────────────────────────────────────────────
// (SAMA PERSIS, TIDAK DIUBAH)

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────

// 1. Ubah StateNotifier menjadi Notifier
class NotificationNotifier extends Notifier<NotificationState> {
  final _supabase = Supabase.instance.client;

  // 2. build() sebagai pengganti constructor
  @override
  NotificationState build() {
    // Jalankan fetch setelah inisialisasi state selesai
    Future.microtask(() => fetchNotifications());
    return const NotificationState();
  }

  // Helper untuk konversi tipe dari Database ke Enum
  NotificationType _parseType(String typeStr) {
    switch (typeStr) {
      case 'statusUpdate': return NotificationType.statusUpdate;
      case 'newComment': return NotificationType.newComment;
      case 'assigned': return NotificationType.assigned;
      case 'newTicket': return NotificationType.newTicket;
      default: return NotificationType.statusUpdate;
    }
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Ambil notifikasi khusus untuk user yang sedang login
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<AppNotification> loadedNotifications = response.map((data) {
        return AppNotification(
          id: data['id'].toString(),
          title: data['title'],
          message: data['message'],
          type: _parseType(data['type']),
          ticketId: data['ticket_id'].toString(),
          createdAt: data['created_at'].toString().substring(0, 10), // Format waktu sementara
          isRead: data['is_read'],
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        notifications: loadedNotifications,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat notifikasi: $e',
      );
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      // Update di Supabase
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);

      // Update di local UI
      final updated = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      print('Gagal update status baca: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Update semua milik user ini di Supabase
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Update di local UI
      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      print('Gagal menandai semua sudah dibaca: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      // Hapus dari Supabase
      await _supabase.from('notifications').delete().eq('id', id);

      // Hapus dari local UI
      final updated = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      print('Gagal menghapus notifikasi: $e');
    }
  }

  Future<void> refresh() => fetchNotifications();
}

// ── Provider ───────────────────────────────────────────────────

// 3. Ubah StateNotifierProvider menjadi NotifierProvider
final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});