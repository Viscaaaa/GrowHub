import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_model.dart';
import '../../../data/repositories/content_repository.dart';
import '../../widgets/content_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'content_detail_screen.dart';

class SavedContentsScreen extends StatefulWidget {
  const SavedContentsScreen({super.key});

  @override
  State<SavedContentsScreen> createState() => _SavedContentsScreenState();
}

class _SavedContentsScreenState extends State<SavedContentsScreen> {
  List<ContentModel> _savedContents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSaved();
  }

  Future<void> _fetchSaved() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await context.read<ContentRepository>().getSavedContents();
      if (mounted) {
        setState(() {
          _savedContents = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Artikel Tersimpan'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat artikel tersimpan...')
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Gagal Memuat',
                  subtitle: _errorMessage,
                  actionText: 'Coba Lagi',
                  onAction: _fetchSaved,
                )
              : _savedContents.isEmpty
                  ? const EmptyState(
                      icon: Icons.bookmark_border,
                      title: 'Belum Ada Bookmark',
                      subtitle:
                          'Anda belum menyimpan artikel apapun. Tekan ikon bookmark pada artikel untuk menyimpannya.',
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchSaved,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _savedContents.length,
                        itemBuilder: (context, idx) {
                          final item = _savedContents[idx];
                          return ContentCard(
                            content: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ContentDetailScreen(
                                    contentId: item.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
