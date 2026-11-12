import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/community_model.dart';
import '../../../logic/community/community_bloc.dart';
import '../../../logic/community/community_event.dart';
import '../../../logic/community/community_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'community_detail_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
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
      appBar: AppBar(
        title: const Text('Komunitas Karyawan'),
      ),
      body: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          if (state is CommunityLoading && state is! CommunityLoaded) {
            return const LoadingIndicator(message: 'Memuat komunitas...');
          }

          if (state is CommunityError) {
            return EmptyState(
              icon: Icons.group_outlined,
              title: 'Gagal Memuat Komunitas',
              subtitle: state.message,
              actionText: 'Coba Lagi',
              onAction: () => context
                  .read<CommunityBloc>()
                  .add(const CommunityFetchRequested()),
            );
          }

          if (state is CommunityLoaded) {
            final communities = state.communities;
            final isJoinedOnly = state.joinedOnly;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<CommunityBloc>()
                    .add(const CommunityFetchRequested(refresh: true));
              },
              child: CustomScrollView(
                slivers: [
                  // Filter header
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari nama komunitas...',
                              prefixIcon: const Icon(Icons.search,
                                  size: 20, color: AppColors.textMuted),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (q) {
                              context.read<CommunityBloc>().add(
                                    CommunityFetchRequested(
                                      query: q.trim(),
                                      refresh: true,
                                    ),
                                  );
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildFilterChip('Semua Komunitas', false,
                                  isJoinedOnly, context),
                              const SizedBox(width: 8),
                              _buildFilterChip('Komunitas yang Saya Ikuti',
                                  true, isJoinedOnly, context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  if (communities.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.group_work_outlined,
                        title: 'Tidak Ada Komunitas',
                        subtitle:
                            'Belum ada komunitas yang sesuai dengan filter ini.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = communities[index];
                          return _buildCommunityCard(item, context);
                        },
                        childCount: communities.length,
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

  Widget _buildFilterChip(
      String label, bool value, bool current, BuildContext context) {
    final isSelected = value == current;
    return InkWell(
      onTap: () {
        context.read<CommunityBloc>().add(
              CommunityFetchRequested(joinedOnly: value, refresh: true),
            );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(CommunityModel item, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommunityDetailScreen(slug: item.slug),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.membersCount} Anggota • ${item.contentsCount} Konten',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<CommunityBloc>()
                          .add(CommunityToggleJoinRequested(item.id));
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: item.isMember
                          ? AppColors.surfaceVariant
                          : AppColors.primary,
                      foregroundColor: item.isMember
                          ? AppColors.textSecondary
                          : Colors.white,
                      side: BorderSide(
                        color: item.isMember
                            ? AppColors.border
                            : AppColors.primary,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      item.isMember ? 'Tergabung' : 'Gabung',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
