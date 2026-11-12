import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/course/course_bloc.dart';
import '../../../logic/course/course_event.dart';
import '../../../logic/home/home_bloc.dart';
import '../../../logic/home/home_event.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class CourseDetailScreen extends StatefulWidget {
  final String slug;
  final int courseId;

  const CourseDetailScreen({
    super.key,
    required this.slug,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseModel? _course;
  bool _isLoading = true;
  bool _isCompleting = false;
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
      final repo = context.read<CourseRepository>();
      final item = await repo.getCourseDetail(widget.slug);
      if (mounted) {
        setState(() {
          _course = item;
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

  Future<void> _completeCourse() async {
    if (_course == null || _course!.isCompleted) return;

    setState(() => _isCompleting = true);
    try {
      final repo = context.read<CourseRepository>();
      final res = await repo.completeCourse(_course!.id);

      if (mounted) {
        setState(() {
          _course = _course!.copyWith(isCompleted: true);
          _isCompleting = false;
        });

        // Refresh global blocs
        context.read<CourseBloc>().add(CourseCompleteRequested(_course!.id));
        context.read<HomeBloc>().add(HomeRefreshRequested());
        context.read<AuthBloc>().add(AuthCheckRequested());

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.military_tech, color: AppColors.gold, size: 28),
                SizedBox(width: 8),
                Text('Selamat!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  res.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                if (res.pointsEarned > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${res.pointsEarned} Poin Didapatkan! 🏆',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hebat!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Materi Belajar'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat materi...')
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Gagal Memuat',
                  subtitle: _errorMessage,
                  actionText: 'Coba Lagi',
                  onAction: _fetchDetail,
                )
              : _course == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    BadgeChip(label: _course!.category),
                                    const SizedBox(width: 8),
                                    BadgeChip(
                                      label: _course!.level,
                                      backgroundColor: AppColors.surfaceVariant,
                                      textColor: AppColors.textSecondary,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '+${_course!.pointsReward} Poin',
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                Text(
                                  _course!.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Durasi baca: ${_course!.durationMinutes} menit',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.people_outline,
                                        size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_course!.completionsCount} karyawan menyelesaikan',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Summary Callout
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primaryLightBorder),
                                  ),
                                  child: Text(
                                    _course!.summary,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.darkForest,
                                      height: 1.45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Full Body
                                Text(
                                  _course!.body ?? _course!.summary,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),

                        // Bottom action
                        Container(
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
                            child: _course!.isCompleted
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.success
                                              .withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: AppColors.success, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Materi Ini Sudah Anda Selesaikan',
                                          style: TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : CustomButton(
                                    text:
                                        'Selesaikan & Klaim +${_course!.pointsReward} Poin',
                                    icon: Icons.emoji_events_outlined,
                                    isLoading: _isCompleting,
                                    onPressed: _completeCourse,
                                  ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
