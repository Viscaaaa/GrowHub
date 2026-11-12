import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';

class LevelProgressCard extends StatelessWidget {
  final UserModel user;
  final int? rank;

  const LevelProgressCard({
    super.key,
    required this.user,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final levelInfo = user.levelInfo;
    final levelName = levelInfo?.name ?? 'Seedling';
    final levelNum = levelInfo?.level ?? 1;
    final nextName = levelInfo?.nextName ?? 'Sprout';
    final pointsToNext = levelInfo?.pointsToNext ?? 0;
    final progress = (levelInfo?.progress ?? 0).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkForest, AppColors.darkForestCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkForest.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primarySubtle.withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.spa,
                      color: AppColors.primarySubtle,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $levelNum • $levelName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${user.points} Total Poin',
                        style: const TextStyle(
                          color: AppColors.primarySubtle,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (rank != null && rank! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Rank #$rank',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primarySubtle),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progress% Selesai',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11.5,
                ),
              ),
              Text(
                levelInfo?.nextLevel != null
                    ? '$pointsToNext poin lagi ke $nextName'
                    : 'Level Maksimal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
