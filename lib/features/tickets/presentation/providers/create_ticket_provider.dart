import 'dart:io';
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;
import 'package:supabase_flutter/supabase_flutter.dart';

// -- Enums --

enum TicketCategory {
  hardware,
  software,
  network,
  account,
  other;

  String get label {
    switch (this) {
      case TicketCategory.hardware:
        return 'Hardware';
      case TicketCategory.software:
        return 'Software';
      case TicketCategory.network:
        return 'Network / Internet';
      case TicketCategory.account:
        return 'Akun & Akses';
      case TicketCategory.other:
        return 'Lainnya';
    }
  }
}

enum TicketPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TicketPriority.low:
        return 'Rendah';
      case TicketPriority.medium:
        return 'Sedang';
      case TicketPriority.high:
        return 'Tinggi';
    }
  }
}

// -- State --

class CreateTicketState {
  final String title;
  final String description;
  final TicketCategory? category;
  final TicketPriority priority;
  final List<File> attachments;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const CreateTicketState({
    this.title = '',
    this.description = '',
    this.category,
    this.priority = TicketPriority.medium,
    this.attachments = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      category != null;

  CreateTicketState copyWith({
    String? title,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    List<File>? attachments,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
  }) {
    return CreateTicketState(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

// -- Notifier --

class CreateTicketNotifier extends StateNotifier<CreateTicketState> {
  final _supabase = Supabase.instance.client;

  CreateTicketNotifier() : super(const CreateTicketState());

  void setTitle(String value) =>
      state = state.copyWith(title: value, error: null);

  void setDescription(String value) =>
      state = state.copyWith(description: value, error: null);

  void setCategory(TicketCategory value) =>
      state = state.copyWith(category: value, error: null);

  void setPriority(TicketPriority value) =>
      state = state.copyWith(priority: value);

  void addAttachment(File file) {
    if (state.attachments.length >= 5) return; // max 5 file
    state = state.copyWith(attachments: [...state.attachments, file]);
  }

  void removeAttachment(int index) {
    final updated = [...state.attachments]..removeAt(index);
    state = state.copyWith(attachments: updated);
  }

  Future<void> submit() async {
    if (!state.isValid) {
      state = state.copyWith(
        error: 'Judul, deskripsi, dan kategori wajib diisi',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Sesi login tidak ditemukan.');

      // 1. Simpan data teks ke tabel 'tickets'
      final ticketResponse = await _supabase
          .from('tickets')
          .insert({
            'title': state.title,
            'description': state.description,
            'category': state.category!.name,
            'priority': state.priority.name,
            'status': 'open',
            'user_id': userId,
          })
          .select()
          .single();

      final ticketId = ticketResponse['id'];

      // 2. Jika ada lampiran file, unggah ke Supabase Storage (Bucket: 'attachments')
      if (state.attachments.isNotEmpty) {
        for (final file in state.attachments) {
          final fileExtension = file.path.split('.').last;
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          final filePath = '$ticketId/$fileName';

          await _supabase.storage.from('attachments').upload(filePath, file);
        }
      }

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Gagal membuat tiket: $e',
      );
    }
  }

  void reset() => state = const CreateTicketState();
}

// -- Provider --

final createTicketProvider =
    StateNotifierProvider.autoDispose<CreateTicketNotifier, CreateTicketState>(
      (ref) => CreateTicketNotifier(),
    );
