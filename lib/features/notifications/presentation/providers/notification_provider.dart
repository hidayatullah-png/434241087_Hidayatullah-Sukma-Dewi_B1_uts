import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model ──────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
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

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? '',
        ticketId: json['ticket_id']?.toString() ?? '',
        createdAt: json['created_at'].toString().substring(0, 16),
        isRead: json['is_read'] ?? false,
      );
}

// ── State ──────────────────────────────────────────────────────

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

class NotificationNotifier extends StateNotifier<NotificationState> {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  NotificationNotifier() : super(const NotificationState()) {
    fetchNotifications();
    _subscribeRealtime();
  }

  // Ambil notifikasi dari Supabase
  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User belum login');

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();

      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat notifikasi: $e',
      );
    }
  }

  // Subscribe Supabase Realtime — listen INSERT baru di tabel notifications
  void _subscribeRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _channel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Notif baru masuk — tambahkan ke list paling atas
            final newNotif = AppNotification.fromJson(payload.newRecord);
            state = state.copyWith(
              notifications: [newNotif, ...state.notifications],
            );
          },
        )
        .subscribe();
  }

  // Mark satu notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);

      final updated = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      print('Gagal mark as read: $e');
    }
  }

  // Mark semua sebagai sudah dibaca
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      print('Gagal mark all as read: $e');
    }
  }

  // Hapus notifikasi
  Future<void> deleteNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
      final updated = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      print('Gagal hapus notifikasi: $e');
    }
  }

  Future<void> refresh() => fetchNotifications();

  @override
  void dispose() {
    // Unsubscribe saat provider di-dispose
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
      (ref) => NotificationNotifier(),
    );

// Provider khusus untuk unread count — dipakai di bell icon
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
