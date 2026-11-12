import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/community_model.dart';
import '../../../data/models/content_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../../widgets/content_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../feed/content_detail_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String slug;

  const CommunityDetailScreen({super.key, required this.slug});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  CommunityModel? _community;
  List<ContentModel> _contents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res =
          await context.read<CommunityRepository>().getCommunityDetail(widget.slug);
      if (mounted) {
        setState(() {
          _community = res.community;
          _contents = res.contents;
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

  Future<void> _toggleJoin() async {
    if (_community == null) return;
    try {
      final res = await context
          .read<CommunityRepository>()
          .toggleJoin(_community!.id);
      final isMember = res['is_member'] == true;
      final membersCount = res['members_count'] is int
          ? res['members_count'] as int
          : _community!.membersCount;

      if (mounted) {
        setState(() {
          _community = _community!.copyWith(
            isMember: isMember,
            membersCount: membersCount,
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_community?.name ?? 'Detail Komunitas'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat komunitas...')
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Gagal Memuat Komunitas',
                  subtitle: _errorMessage,
                  actionText: 'Coba Lagi',
                  onAction: _fetchDetail,
                )
              : _community == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Community Header Card
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.groups,
                                          color: AppColors.primary, size: 30),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _community!.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_community!.membersCount} Anggota • ${_community!.contentsCount} Pengetahuan',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_community!.description != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    _community!.description!,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _toggleJoin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _community!.isMember
                                          ? AppColors.surfaceVariant
                                          : AppColors.primary,
                                      foregroundColor: _community!.isMember
                                          ? AppColors.textPrimary
                                          : Colors.white,
                                    ),
                                    child: Text(
                                      _community!.isMember
                                          ? 'Tergabung (Klik untuk Keluar)'
                                          : 'Gabung Komunitas Ini',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Contents list
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Diskusi & Pengetahuan (${_contents.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_contents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Belum ada konten dalam komunitas ini.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          else
                            ..._contents.map((item) {
                              return ContentCard(
                                content: item,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ContentDetailScreen(
                                          contentId: item.id),
                                    ),
                                  );
                                },
                              );
                            }),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }
}
