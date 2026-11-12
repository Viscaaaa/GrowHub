import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/content/content_bloc.dart';
import '../../../logic/content/content_event.dart';
import '../../../logic/content/content_state.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/content_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'content_detail_screen.dart';
import 'create_content_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text(
          'Bagikan Pengetahuan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateContentScreen()),
          );
        },
      ),
      body: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          if (state is ContentLoading && state is! ContentLoaded) {
            return const LoadingIndicator(message: 'Memuat feed pengetahuan...');
          }

          if (state is ContentError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal Memuat Feed',
              subtitle: state.message,
              actionText: 'Coba Lagi',
              onAction: () =>
                  context.read<ContentBloc>().add(const ContentFetchRequested()),
            );
          }

          if (state is ContentLoaded) {
            final categories = state.categories;
            final contents = state.contents;
            final selectedCat = state.selectedCategory;
            final currentSort = state.sort;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<ContentBloc>()
                    .add(const ContentFetchRequested(refresh: true));
              },
              child: CustomScrollView(
                slivers: [
                  // Search & Filter header
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          // Search field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari SOP, tips kerja, modul belajar...',
                              prefixIcon: const Icon(Icons.search,
                                  size: 20, color: AppColors.textMuted),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        context
                                            .read<ContentBloc>()
                                            .add(const ContentSearchChanged(''));
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (query) {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentSearchChanged(query.trim()));
                            },
                          ),
                          const SizedBox(height: 10),

                          // Sort chips (Terbaru, Populer, Trending)
                          Row(
                            children: [
                              const Text(
                                'Urutkan: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _buildSortChip('Terbaru', 'latest', currentSort),
                              const SizedBox(width: 6),
                              _buildSortChip('Populer', 'popular', currentSort),
                              const SizedBox(width: 6),
                              _buildSortChip('Trending', 'trending', currentSort),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Horizontal Category Filter
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            if (idx == 0) {
                              final isAll = selectedCat == null;
                              return BadgeChip(
                                label: 'Semua Kategori',
                                isSelected: isAll,
                                onTap: () {
                                  context.read<ContentBloc>().add(
                                        const ContentFilterCategoryChanged(null),
                                      );
                                },
                              );
                            }
                            final cat = categories[idx - 1];
                            final isSel = selectedCat == cat.slug;
                            return BadgeChip(
                              label: cat.name,
                              isSelected: isSel,
                              onTap: () {
                                context.read<ContentBloc>().add(
                                      ContentFilterCategoryChanged(
                                          isSel ? null : cat.slug),
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Contents list or empty state
                  if (contents.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'Belum Ada Konten',
                        subtitle:
                            'Belum ada pengetahuan yang dibagikan untuk kategori atau pencarian ini.',
                        actionText: 'Bagikan Pertama Kali',
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
                            onLike: () {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentLikeToggled(item.id));
                            },
                            onSave: () {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentSaveToggled(item.id));
                            },
                          );
                        },
                        childCount: contents.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSortChip(String label, String value, String current) {
    final isSelected = current == value;
    return InkWell(
      onTap: () {
        context.read<ContentBloc>().add(ContentSortChanged(value));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkForest : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
