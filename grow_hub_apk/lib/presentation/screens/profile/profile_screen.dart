import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/user_model.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/home/home_bloc.dart';
import '../../../logic/home/home_state.dart';
import '../../../logic/profile/profile_bloc.dart';
import '../../../logic/profile/profile_event.dart';
import '../../widgets/level_progress_card.dart';
import '../../widgets/streak_card.dart';
import '../auth/change_password_dialog.dart';
import '../communities/communities_screen.dart';
import '../feed/saved_contents_screen.dart';
import '../my_contributions/my_contributions_screen.dart';
import '../support/faqs_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileFetchRequested());
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun GrowHub?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          UserModel? user;
          if (authState is AuthAuthenticated) {
            user = authState.user;
          }

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<HomeBloc, HomeState>(
            builder: (context, homeState) {
              DashboardMeModel? myDashboard;
              if (homeState is HomeLoaded) {
                myDashboard = homeState.myDashboard;
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context
                      .read<ProfileBloc>()
                      .add(const ProfileFetchRequested(refresh: true));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      // Profile Header Card
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                user!.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'K',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.position ?? 'Category Specialist'} • ${user.department ?? 'Operasional'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Role Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primaryLightBorder),
                                  ),
                                  child: const Text(
                                    'ROLE: EMPLOYEE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                '"${user.bio}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Level Progress Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LevelProgressCard(
                          user: user,
                          rank: myDashboard?.rank,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Daily Streak Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StreakCard(user: user),
                      ),

                      const SizedBox(height: 20),

                      // Badges Showcase (Gamification)
                      if (myDashboard != null &&
                          myDashboard.badges.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.military_tech,
                                    color: AppColors.gold, size: 22),
                                const SizedBox(width: 6),
                                const Text(
                                  'Lencana Pencapaian',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${myDashboard.badges.where((b) => b.earned).length}/${myDashboard.badges.length} Terbuka',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 118,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: myDashboard.badges.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final badge = myDashboard!.badges[idx];
                              return _buildBadgeCard(badge);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Recent Point History
                      if (myDashboard != null &&
                          myDashboard.recentPoints.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.history,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 6),
                                const Text(
                                  'Riwayat Poin Terakhir',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myDashboard.recentPoints.take(4).length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final tx = myDashboard!.recentPoints[idx];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  tx.description ?? tx.action,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormatter.timeAgo(tx.createdAt),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tx.points < 0
                                        ? AppColors.errorLight
                                        : AppColors.goldLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${tx.points > 0 ? '+' : ''}${tx.points} Poin',
                                    style: TextStyle(
                                      color: tx.points < 0
                                          ? AppColors.error
                                          : AppColors.gold,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Navigation Menus Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Column(
                            children: [
                              _buildMenuTile(
                                icon: Icons.description_outlined,
                                title: 'Kontribusi Saya',
                                subtitle: 'Pantau status artikel & revisi',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyContributionsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              _buildMenuTile(
                                icon: Icons.bookmark_border,
                                title: 'Artikel Tersimpan',
                                subtitle: 'Daftar materi yang Anda simpan',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SavedContentsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              _buildMenuTile(
                                icon: Icons.group_outlined,
                                title: 'Komunitas Karyawan',
                                subtitle: 'Daftar grup & forum diskusi',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CommunitiesScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              _buildMenuTile(
                                icon: Icons.help_outline,
                                title: 'Pusat Bantuan & FAQ',
                                subtitle: 'Pertanyaan seputar sistem & tiket',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const FaqsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Settings & Logout Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Column(
                            children: [
                              _buildMenuTile(
                                icon: Icons.edit_outlined,
                                title: 'Edit Profil',
                                subtitle: 'Ubah nama, email, lokasi penempatan',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfileScreen(user: user!),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              _buildMenuTile(
                                icon: Icons.lock_outline,
                                title: 'Ganti Password',
                                subtitle: 'Perbarui kata sandi akun Anda',
                                onTap: () async {
                                  final changed = await showDialog<Object?>(
                                    context: context,
                                    builder: (_) =>
                                        const ChangePasswordDialog(
                                            isMandatory: false),
                                  );
                                  if (changed == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Password berhasil diperbarui.'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const Divider(height: 1),
                              _buildMenuTile(
                                icon: Icons.logout,
                                iconColor: AppColors.error,
                                title: 'Keluar (Logout)',
                                titleColor: AppColors.error,
                                onTap: _confirmLogout,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.earned ? AppColors.gold : AppColors.border,
          width: badge.earned ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                badge.earned ? Icons.verified : Icons.lock_outline,
                size: 20,
                color: badge.earned ? AppColors.gold : AppColors.textMuted,
              ),
              const Spacer(),
              if (badge.earned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Didapat',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: badge.earned
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
