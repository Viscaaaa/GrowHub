import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/leaderboard/leaderboard_bloc.dart';
import '../../../logic/leaderboard/leaderboard_event.dart';
import '../../../logic/leaderboard/leaderboard_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int currentUserId = 0;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardLoading && state is! LeaderboardLoaded) {
            return const LoadingIndicator(message: 'Memuat papan peringkat...');
          }

          if (state is LeaderboardError) {
            return EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Gagal Memuat Peringkat',
              subtitle: state.message,
              actionText: 'Coba Lagi',
              onAction: () => context
                  .read<LeaderboardBloc>()
                  .add(const LeaderboardFetchRequested()),
            );
          }

          if (state is LeaderboardLoaded) {
            final data = state.data;
            final leaders = data.leaders;
            final departments = ['Semua', ...data.departments];
            final currentDept = state.department ?? 'Semua';
            final currentPeriod = state.period;
            final myData = data.me;

            final top1 = leaders.isNotEmpty ? leaders[0] : null;
            final top2 = leaders.length > 1 ? leaders[1] : null;
            final top3 = leaders.length > 2 ? leaders[2] : null;
            final remainingLeaders =
                leaders.length > 3 ? leaders.sublist(3) : <LeaderboardItemModel>[];

            return Column(
              children: [
                // Filter controls
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      // Period Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildPeriodTab('Semua Waktu', 'all', currentPeriod, context),
                            _buildPeriodTab('Bulan Ini', 'month', currentPeriod, context),
                            _buildPeriodTab('Minggu Ini', 'week', currentPeriod, context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Department Filter Dropdown
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          const Text(
                            'Departemen: ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: departments.contains(currentDept)
                                      ? currentDept
                                      : 'Semua',
                                  isExpanded: true,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: departments.map((d) {
                                    return DropdownMenuItem<String>(
                                      value: d,
                                      child: Text(d),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    context.read<LeaderboardBloc>().add(
                                          LeaderboardDepartmentChanged(
                                              val == 'Semua' ? null : val),
                                        );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Leaderboard list
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context
                          .read<LeaderboardBloc>()
                          .add(const LeaderboardFetchRequested(refresh: true));
                    },
                    child: leaders.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: EmptyState(
                                icon: Icons.emoji_events_outlined,
                                title: 'Belum Ada Data Peringkat',
                                subtitle:
                                    'Belum ada aktivitas poin untuk periode atau departemen ini.',
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 90),
                            children: [
                              // Podium Top 3
                              if (top1 != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 16),
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.darkForest,
                                        AppColors.darkForestCard
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      // 2nd Place
                                      if (top2 != null)
                                        _buildPodiumItem(
                                            top2, 2, const Color(0xFF94A3B8), 100),
                                      // 1st Place (Center & taller)
                                      _buildPodiumItem(
                                          top1, 1, AppColors.gold, 130),
                                      // 3rd Place
                                      if (top3 != null)
                                        _buildPodiumItem(
                                            top3, 3, const Color(0xFFCD7F32), 85),
                                    ],
                                  ),
                                ),

                              // Other Ranks (4+)
                              if (remainingLeaders.isNotEmpty)
                                ...remainingLeaders.map((item) {
                                  final isMe = item.id == currentUserId;
                                  return _buildRankRow(item, isMe);
                                }),
                            ],
                          ),
                  ),
                ),

                // Sticky footer: Peringkat Saya
                if (myData != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Center(
                              child: Text(
                                myData.rank != null ? '#${myData.rank}' : '-',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Peringkat Anda',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  myData.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${myData.score} Poin',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (myData.currentStreak > 0)
                                Text(
                                  '${myData.currentStreak} 🔥 streak',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.fireOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPeriodTab(
      String label, String value, String current, BuildContext context) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<LeaderboardBloc>().add(LeaderboardPeriodChanged(value));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.darkForest : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(
      LeaderboardItemModel item, int rank, Color medalColor, double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 28 : 22,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                item.name.isNotEmpty ? item.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: rank == 1 ? 18 : 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 85,
          child: Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          item.department ?? 'Employee',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: medalColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: medalColor.withOpacity(0.5)),
          ),
          child: Text(
            '${item.score} Pts',
            style: TextStyle(
              color: medalColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardItemModel item, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary : AppColors.border,
          width: isMe ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${item.rank ?? ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isMe ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          CircleAvatar(
            radius: 17,
            backgroundColor: isMe ? AppColors.primary : AppColors.surfaceVariant,
            child: Text(
              item.name.isNotEmpty ? item.name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Anda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${item.department ?? 'Operasional'}${item.position != null && item.position!.isNotEmpty ? ' • ${item.position}' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.score} Pts',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (item.currentStreak > 0)
                Text(
                  '${item.currentStreak} 🔥',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.fireOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
