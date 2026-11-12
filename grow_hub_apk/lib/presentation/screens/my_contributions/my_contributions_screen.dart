import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/content_model.dart';
import '../../../logic/my_content/my_content_bloc.dart';
import '../../../logic/my_content/my_content_event.dart';
import '../../../logic/my_content/my_content_state.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../feed/content_detail_screen.dart';
import '../feed/create_content_screen.dart';

class MyContributionsScreen extends StatelessWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kontribusi Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Buat Baru',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateContentScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MyContentBloc, MyContentState>(
        builder: (context, state) {
          if (state is MyContentLoading && state is! MyContentLoaded) {
            return const LoadingIndicator(message: 'Memuat kontribusi Anda...');
          }

          if (state is MyContentError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal Memuat Kontribusi',
              subtitle: state.message,
              actionText: 'Coba Lagi',
              onAction: () => context
                  .read<MyContentBloc>()
                  .add(const MyContentFetchRequested()),
            );
          }

          if (state is MyContentLoaded) {
            final contents = state.contents;
            final counts = state.counts;
            final currentStatus = state.currentStatus;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<MyContentBloc>()
                    .add(const MyContentFetchRequested(refresh: true));
              },
              child: CustomScrollView(
                slivers: [
                  // Engagement stats overview
                  if (state.engagement != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Dampak Pengetahuan Anda',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildImpactCol(
                                  '${state.engagement!['likes'] ?? 0}',
                                  'Suka',
                                  Icons.favorite,
                                  AppColors.error,
                                ),
                                _buildImpactCol(
                                  '${state.engagement!['comments'] ?? 0}',
                                  'Komentar',
                                  Icons.chat_bubble_outline,
                                  AppColors.blue,
                                ),
                                _buildImpactCol(
                                  '${state.engagement!['views'] ?? 0}',
                                  'Dilihat',
                                  Icons.remove_red_eye_outlined,
                                  AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Horizontal Status Filter Tabs
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildTabChip('Semua', 'all', counts['all'] ?? 0,
                                currentStatus, context),
                            const SizedBox(width: 8),
                            _buildTabChip('Diterbitkan', 'published',
                                counts['published'] ?? 0, currentStatus, context),
                            const SizedBox(width: 8),
                            _buildTabChip('Menunggu Review', 'pending',
                                counts['pending'] ?? 0, currentStatus, context),
                            const SizedBox(width: 8),
                            _buildTabChip('Draft', 'draft',
                                counts['draft'] ?? 0, currentStatus, context),
                            const SizedBox(width: 8),
                            _buildTabChip('Perlu Revisi', 'rejected',
                                counts['rejected'] ?? 0, currentStatus, context),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // Content list
                  if (contents.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.post_add,
                        title: 'Tidak Ada Konten',
                        subtitle:
                            'Belum ada konten pada status ini. Ayo bagikan pengalaman kerja Anda!',
                        actionText: 'Tulis Konten',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CreateContentScreen()),
                          );
                        },
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = contents[index];
                          return _buildContributionCard(item, context);
                        },
                        childCount: contents.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildImpactCol(
      String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip(String label, String status, int count,
      String currentStatus, BuildContext context) {
    final isSelected = currentStatus == status;
    return InkWell(
      onTap: () {
        context.read<MyContentBloc>().add(MyContentStatusChanged(status));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard(ContentModel item, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BadgeChip.status(item.status),
                Text(
                  DateFormatter.timeAgo(item.updatedAt ?? item.createdAt),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),

            // Reviewer Note if rejected
            if (item.isRejected && item.reviewNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.feedback_outlined,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Tim Reviewer:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            item.reviewNote!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Row(
              children: [
                if (item.isPublished) ...[
                  Text(
                    '${item.likesCount} suka • ${item.commentsCount} komentar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ContentDetailScreen(contentId: item.id),
                        ),
                      );
                    },
                    child: const Text('Lihat Artikel'),
                  ),
                ] else ...[
                  // Edit & Delete options for drafts / rejected
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit & Kirim'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateContentScreen(editContent: item),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Konten?'),
                          content: Text(
                              'Apakah Anda yakin ingin menghapus "${item.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                context
                                    .read<MyContentBloc>()
                                    .add(MyContentDeleteRequested(item.id));
                              },
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
