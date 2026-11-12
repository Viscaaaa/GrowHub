import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/course/course_bloc.dart';
import '../../../logic/course/course_event.dart';
import '../../../logic/course/course_state.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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
      body: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          if (state is CourseLoading && state is! CourseLoaded) {
            return const LoadingIndicator(message: 'Memuat materi belajar...');
          }

          if (state is CourseError) {
            return EmptyState(
              icon: Icons.school_outlined,
              title: 'Gagal Memuat Materi',
              subtitle: state.message,
              actionText: 'Coba Lagi',
              onAction: () =>
                  context.read<CourseBloc>().add(const CourseFetchRequested()),
            );
          }

          if (state is CourseLoaded) {
            final courses = state.courses;
            final categories = state.categories;
            final selectedCat = state.selectedCategory;
            final progressPercent = state.total > 0
                ? (state.completed / state.total).clamp(0.0, 1.0)
                : 0.0;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<CourseBloc>()
                    .add(const CourseFetchRequested(refresh: true));
              },
              child: CustomScrollView(
                slivers: [
                  // Learning summary progress header
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.school,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Learning Center',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Tingkatkan keterampilan & kumpulkan poin',
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
                          const SizedBox(height: 16),

                          // Progress bar
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Progres Belajar Anda',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${state.completed} dari ${state.total} Materi Selesai',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    minHeight: 7,
                                    backgroundColor: AppColors.border,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Search bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari modul materi...',
                              prefixIcon: const Icon(Icons.search,
                                  size: 20, color: AppColors.textMuted),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (q) {
                              context
                                  .read<CourseBloc>()
                                  .add(CourseSearchChanged(q.trim()));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category horizontal chips
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final cat = categories[idx];
                            final isSel = selectedCat == cat ||
                                (selectedCat == null && cat == 'Semua');
                            return BadgeChip(
                              label: cat,
                              isSelected: isSel,
                              onTap: () {
                                context
                                    .read<CourseBloc>()
                                    .add(CourseCategoryChanged(cat));
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Course list
                  if (courses.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.school_outlined,
                        title: 'Tidak Ada Materi',
                        subtitle: 'Belum ada materi untuk kategori ini.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = courses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CourseDetailScreen(
                                      slug: item.slug,
                                      courseId: item.id,
                                    ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        BadgeChip(
                                          label: item.category,
                                          fontSize: 11,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.goldLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+${item.pointsReward} Poin',
                                            style: const TextStyle(
                                              color: AppColors.gold,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
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
                                    const SizedBox(height: 6),
                                    Text(
                                      item.summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined,
                                            size: 15,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.durationMinutes} menit',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        BadgeChip(
                                          label: item.level,
                                          backgroundColor:
                                              AppColors.surfaceVariant,
                                          textColor: AppColors.textSecondary,
                                          fontSize: 10.5,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                        ),
                                        const Spacer(),
                                        if (item.isCompleted)
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  size: 16,
                                                  color: AppColors.success),
                                              SizedBox(width: 4),
                                              Text(
                                                'Selesai',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          const Text(
                                            'Mulai Belajar →',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: courses.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
