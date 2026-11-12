import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/content_model.dart';
import '../../../data/repositories/content_repository.dart';
import '../../../logic/content/content_bloc.dart';
import '../../../logic/content/content_event.dart';
import '../../../logic/my_content/my_content_bloc.dart';
import '../../../logic/my_content/my_content_event.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateContentScreen extends StatefulWidget {
  final ContentModel? editContent;

  const CreateContentScreen({super.key, this.editContent});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.editContent != null) {
      _titleController.text = widget.editContent!.title;
      _bodyController.text = widget.editContent!.body;
      _tagsController.text = widget.editContent!.tags.join(', ');
      _selectedCategoryId = widget.editContent!.categoryId;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await context.read<ContentRepository>().getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
          if (_selectedCategoryId == null && cats.isNotEmpty) {
            _selectedCategoryId = cats.first.id;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveContent(String action) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori pengetahuan terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final repo = context.read<ContentRepository>();

      if (widget.editContent != null) {
        await repo.updateContent(
          id: widget.editContent!.id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          categoryId: _selectedCategoryId!,
          tags: tags,
          action: action,
        );
      } else {
        await repo.createContent(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          categoryId: _selectedCategoryId!,
          tags: tags,
          action: action,
        );
      }

      if (mounted) {
        context.read<ContentBloc>().add(const ContentFetchRequested(refresh: true));
        context.read<MyContentBloc>().add(const MyContentFetchRequested(refresh: true));

        final msg = action == 'submit'
            ? 'Konten berhasil dikirim dan sedang menunggu review tim HC/Reviewer.'
            : 'Konten berhasil disimpan sebagai Draft.';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  action == 'submit' ? Icons.check_circle : Icons.save,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(action == 'submit' ? 'Berhasil Dikirim' : 'Tersimpan'),
              ],
            ),
            content: Text(msg),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editContent != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Konten' : 'Bagikan Pengetahuan'),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLightBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bagikan praktik terbaik, tips kerja di toko, atau inovasi untuk rekan kerja lainnya.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.darkForest,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    CustomTextField(
                      controller: _titleController,
                      label: 'Judul Pengetahuan',
                      hint: 'Contoh: 5 Cara Efektif Display Barang di Toko',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Judul wajib diisi';
                        }
                        if (val.trim().length < 5) {
                          return 'Judul minimal 5 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Pilih kategori pengetahuan' : null,
                    ),
                    const SizedBox(height: 16),

                    // Body
                    CustomTextField(
                      controller: _bodyController,
                      label: 'Isi Pengetahuan',
                      hint: 'Jelaskan secara lengkap langkah-langkah, latar belakang, dan solusi yang Anda terapkan...',
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Isi pengetahuan wajib diisi';
                        }
                        if (val.trim().length < 20) {
                          return 'Isi pengetahuan minimal 20 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    CustomTextField(
                      controller: _tagsController,
                      label: 'Tag / Label (Opsional)',
                      hint: 'display, stok, kasir, pelayanan (pisahkan dengan koma)',
                      helperText: 'Gunakan koma untuk memisahkan kata kunci tag.',
                    ),
                    const SizedBox(height: 28),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Simpan Draft',
                            isOutlined: true,
                            isLoading: _isSubmitting,
                            onPressed:
                                _isSubmitting ? null : () => _saveContent('draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Kirim Review',
                            icon: Icons.send_rounded,
                            isLoading: _isSubmitting,
                            onPressed:
                                _isSubmitting ? null : () => _saveContent('submit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
