// lib/features/tickets/presentation/screens/create_ticket_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/create_ticket_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -- Image Picker --

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (picked == null) return;
      ref.read(createTicketProvider.notifier).addAttachment(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal mengambil gambar');
    }
  }

  Future<void> _pickFile() async {
    try {
      final picked = await _picker.pickMedia();
      if (picked == null) return;
      ref.read(createTicketProvider.notifier).addAttachment(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memilih file');
    }
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.wrnDarkInput : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _BottomSheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Ambil Foto dari Kamera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _BottomSheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Pilih dari Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _BottomSheetOption(
                icon: Icons.attach_file_rounded,
                label: 'Pilih File / Video',
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // -- Submit ---

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    await ref.read(createTicketProvider.notifier).submit();

    final state = ref.read(createTicketProvider);
    if (!mounted) return;

    if (state.isSuccess) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.wrnDarkInput
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.wrnBtsPurple.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.wrnBtsPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tiket Berhasil Dibuat!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tim helpdesk akan segera menangani laporan kamu.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.pop(context); // kembali ke screen sebelumnya
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wrnBtsPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Oke'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.wrnBtsPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // -- Build ---

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTicketProvider);
    final notifier = ref.read(createTicketProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Judul --
            _SectionLabel(text: 'Judul Masalah', isRequired: true),
            const SizedBox(height: 8),
            _InputField(
              controller: _titleController,
              hint: 'Contoh: Printer lantai 3 tidak bisa digunakan',
              onChanged: notifier.setTitle,
              maxLines: 1,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // -- Deskripsi --
            _SectionLabel(text: 'Deskripsi', isRequired: true),
            const SizedBox(height: 8),
            _InputField(
              controller: _descController,
              hint:
                  'Jelaskan masalah secara detail: kapan terjadi, pesan error yang muncul, langkah yang sudah dicoba...',
              onChanged: notifier.setDescription,
              maxLines: 5,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // -- Kategori --
            _SectionLabel(text: 'Kategori', isRequired: true),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TicketCategory.values.map((cat) {
                final isSelected = state.category == cat;
                return GestureDetector(
                  onTap: () => notifier.setCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.wrnBtsPurple
                          : isDark
                          ? AppColors.wrnDarkInput
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.wrnBtsPurple
                            : isDark
                            ? AppColors.wrnShapePurple.withOpacity(0.3)
                            : cs.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // -- Prioritas --
            _SectionLabel(text: 'Prioritas', isRequired: false),
            const SizedBox(height: 8),
            Row(
              children: TicketPriority.values.map((p) {
                final isSelected = state.priority == p;
                final color = _priorityColor(p);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.setPriority(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                        right: p != TicketPriority.high ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : isDark
                            ? AppColors.wrnDarkInput
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : isDark
                              ? AppColors.wrnShapePurple.withOpacity(0.3)
                              : cs.outlineVariant.withOpacity(0.5),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _priorityIcon(p),
                            color: isSelected
                                ? color
                                : cs.onSurface.withOpacity(0.4),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color
                                  : cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // -- Attachment --
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(text: 'Lampiran (maks. 5)', isRequired: false),
                Text(
                  '${state.attachments.length}/5',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Preview grid attachment
            if (state.attachments.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: state.attachments.length,
                itemBuilder: (context, i) {
                  final file = state.attachments[i];
                  final isImage = _isImageFile(file.path);
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isImage
                            ? Image.file(
                                file,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: isDark
                                    ? AppColors.wrnDarkInput
                                    : cs.surfaceContainerLow,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file_outlined,
                                      color: AppColors.wrnLightPurple,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      file.path.split('/').last,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: cs.onSurface.withOpacity(0.6),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      // Tombol hapus
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => notifier.removeAttachment(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
            ],

            // Tombol tambah lampiran
            if (state.attachments.length < 5)
              GestureDetector(
                onTap: _showAttachmentOptions,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.wrnDarkInput
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.wrnShapePurple.withOpacity(0.3)
                          : cs.outlineVariant.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.wrnLightPurple,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tambah Foto / File',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Kamera, Gallery, atau File',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // -- Error message --
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFCF6679),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                        color: Color(0xFFCF6679),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // -- Submit button --
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wrnBtsPurple,
                  disabledBackgroundColor: AppColors.wrnBtsPurple.withOpacity(
                    0.5,
                  ),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Kirim Tiket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // -- Helpers ---

  bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.gif');
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.low:
        return const Color(0xFF4CAF50);
      case TicketPriority.medium:
        return AppColors.wrnBtsPurple;
      case TicketPriority.high:
        return AppColors.wrnShapeRose;
    }
  }

  IconData _priorityIcon(TicketPriority p) {
    switch (p) {
      case TicketPriority.low:
        return Icons.arrow_downward_rounded;
      case TicketPriority.medium:
        return Icons.remove_rounded;
      case TicketPriority.high:
        return Icons.arrow_upward_rounded;
    }
  }
}

// -- Helper Widgets ---

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const _SectionLabel({required this.text, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.75),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFCF6679),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool isDark;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.maxLines,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrnDarkInput : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.wrnShapePurple.withOpacity(0.25)
              : cs.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: cs.onSurface.withOpacity(0.35),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.wrnBtsPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.wrnBtsPurple, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
