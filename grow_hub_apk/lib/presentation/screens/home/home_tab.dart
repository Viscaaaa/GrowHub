import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/content/content_bloc.dart';
import '../../../logic/content/content_event.dart';
import '../../../logic/home/home_bloc.dart';
import '../../../logic/home/home_event.dart';
import '../../../logic/home/home_state.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/content_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/level_progress_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/streak_card.dart';
import '../courses/course_detail_screen.dart';
import '../feed/content_detail_screen.dart';

class HomeTab extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeTab({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        UserModel? user;
        if (authState is AuthAuthenticated) {
          user = authState.user;
        }

        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading && state is! HomeLoaded) {
              return const LoadingIndicator(message: 'Memuat beranda...');
            }

            if (state is HomeError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Gagal Memuat Beranda',
                subtitle: state.message,
                actionText: 'Coba Lagi',
                onAction: () =>
                    context.read<HomeBloc>().add(HomeFetchRequested()),
              );
            }

            if (state is HomeLoaded) {
              final homeData = state.homeData;
              final currentUser = user ??
                  UserModel(id: 0, nip: '', name: 'Karyawan', role: 'employee');

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<HomeBloc>().add(HomeRefreshRequested());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Greeting Bar
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                currentUser.name.isNotEmpty
                                    ? currentUser.name[0].toUpperCase()
                                    : 'K',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${currentUser.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${currentUser.department ?? 'Operasional'}${currentUser.position != null && currentUser.position!.isNotEmpty ? ' • ${currentUser.position}' : ''}',
                                    style: const TextStyle(
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

                      const SizedBox(height: 12),

                      // Level Progress Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LevelProgressCard(
                          user: currentUser,
                          rank: homeData.myRank,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Daily Streak Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StreakCard(user: currentUser),
                      ),

                      const SizedBox(height: 18),

                      // Quick Stats Overview
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildStatBox(
                              'Konten Publish',
                              '${homeData.stats.publishedContents}',
                              Icons.menu_book,
                              AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBox(
                              'Kontributor',
                              '${homeData.stats.contributors}',
                              Icons.people_outline,
                              AppColors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBox(
                              'Karyawan Aktif',
                              '${homeData.stats.employees}',
                              Icons.storefront_outlined,
                              AppColors.purple,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Categories Horizontal
                      if (homeData.categories.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kategori Pengetahuan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => onNavigateTab?.call(1), // Go to Feed
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: homeData.categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final cat = homeData.categories[idx];
                              return BadgeChip(
                                label: '${cat.name} (${cat.contentsCount})',
                                onTap: () {
                                  context.read<ContentBloc>().add(
                                        ContentFilterCategoryChanged(cat.slug),
                                      );
                                  onNavigateTab?.call(1);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // Trending Knowledge Section
                      if (homeData.trending.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up,
                                  color: AppColors.fireOrange, size: 20),
                              const SizedBox(width: 6),
                              const Text(
                                'Sedang Tren',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  context.read<ContentBloc>().add(
                                        const ContentSortChanged('trending'),
                                      );
                                  onNavigateTab?.call(1);
                                },
                                child: const Text(
                                  'Lainnya',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...homeData.trending.take(2).map((content) {
                          return ContentCard(
                            content: content,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ContentDetailScreen(contentId: content.id),
                                ),
                              );
                            },
                            onLike: () {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentLikeToggled(content.id));
                            },
                            onSave: () {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentSaveToggled(content.id));
                            },
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // Featured Learning Center
                      if (homeData.courses.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.school_outlined,
                                      color: AppColors.primary, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Pusat Belajar Karyawan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => onNavigateTab?.call(2), // Belajar
                                child: const Text(
                                  'Semua',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 145,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: homeData.courses.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final course = homeData.courses[idx];
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(
                                        slug: course.slug,
                                        courseId: course.id,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 250,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          BadgeChip(
                                            label: course.category,
                                            fontSize: 10,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldLight,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '+${course.pointsReward} Poin',
                                              style: const TextStyle(
                                                color: AppColors.gold,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        course.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined,
                                              size: 14,
                                              color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${course.durationMinutes} menit',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (course.isCompleted)
                                            const Row(
                                              children: [
                                                Icon(Icons.check_circle,
                                                    size: 14,
                                                    color: AppColors.success),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Selesai',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // Latest Knowledge Section
                      if (homeData.latest.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Pengetahuan Terbaru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...homeData.latest.take(3).map((content) {
                          return ContentCard(
                            content: content,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ContentDetailScreen(contentId: content.id),
                                ),
                              );
                            },
                            onLike: () {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentLikeToggled(content.id));
                            },
                            onSave: () {
                              context
                                  .read<ContentBloc>()
                                  .add(ContentSaveToggled(content.id));
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildStatBox(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
