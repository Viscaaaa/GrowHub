import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/support_model.dart';
import '../../../data/repositories/support_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  List<FaqItemModel> _faqs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await context.read<SupportRepository>().getFaqs();
      if (mounted) {
        setState(() {
          _faqs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateTicketSheet() {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'general';
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kirim Tiket Bantuan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: subjectController,
                      label: 'Subjek Kendala',
                      hint: 'Contoh: Kendala login / pertanyaan point...',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Subjek wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kategori Kendala',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'general', child: Text('Umum')),
                        DropdownMenuItem(
                            value: 'account', child: Text('Akun & Login')),
                        DropdownMenuItem(
                            value: 'content', child: Text('Konten & Feed')),
                        DropdownMenuItem(
                            value: 'technical', child: Text('Kendala Teknis')),
                        DropdownMenuItem(
                            value: 'suggestion',
                            child: Text('Kritik & Saran')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => category = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: messageController,
                      label: 'Deskripsi Pesan',
                      hint: 'Jelaskan kendala Anda secara detail...',
                      maxLines: 4,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pesan wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Kirim Tiket Bantuan',
                      isLoading: isSending,
                      onPressed: isSending
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() ?? false) {
                                setModalState(() => isSending = true);
                                final repo = context.read<SupportRepository>();
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await repo.createTicket(
                                    subject: subjectController.text.trim(),
                                    category: category,
                                    message: messageController.text.trim(),
                                  );
                                  if (mounted) {
                                    Navigator.of(ctx).pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Tiket bantuan berhasil dikirim ke tim HC/IT.'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSending = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group FAQs by 'group'
    Map<String, List<FaqItemModel>> grouped = {};
    for (var f in _faqs) {
      grouped.putIfAbsent(f.group, () => []).add(f);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bantuan & FAQ'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Hubungi Tim HC / Kirim Tiket',
            icon: Icons.support_agent,
            onPressed: _showCreateTicketSheet,
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat FAQ...')
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.help_outline,
                  title: 'Gagal Memuat FAQ',
                  subtitle: _errorMessage,
                  actionText: 'Coba Lagi',
                  onAction: _fetchFaqs,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryLightBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.help_center_outlined,
                              color: AppColors.primary, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pusat Panduan Karyawan',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkForest,
                                  ),
                                ),
                                Text(
                                  'Temukan jawaban seputar login, gamifikasi, dan aturan sharing di GrowHub.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grouped FAQs
                    for (var entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: entry.value.map((faq) {
                            return ExpansionTile(
                              shape: const Border(),
                              title: Text(
                                faq.question,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      faq.answer,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
