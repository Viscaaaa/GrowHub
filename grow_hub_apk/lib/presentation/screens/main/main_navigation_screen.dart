import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/community/community_bloc.dart';
import '../../../logic/community/community_event.dart';
import '../../../logic/content/content_bloc.dart';
import '../../../logic/content/content_event.dart';
import '../../../logic/course/course_bloc.dart';
import '../../../logic/course/course_event.dart';
import '../../../logic/home/home_bloc.dart';
import '../../../logic/home/home_event.dart';
import '../../../logic/leaderboard/leaderboard_bloc.dart';
import '../../../logic/leaderboard/leaderboard_event.dart';
import '../../../logic/my_content/my_content_bloc.dart';
import '../../../logic/my_content/my_content_event.dart';
import '../../../logic/notification/notification_bloc.dart';
import '../../../logic/notification/notification_event.dart';
import '../../../logic/notification/notification_state.dart';
import '../../widgets/ethics_notice_dialog.dart';
import '../auth/login_screen.dart';
import '../courses/courses_screen.dart';
import '../feed/feed_tab.dart';
import '../feed/saved_contents_screen.dart';
import '../home/home_tab.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _ethicsDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch for all tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(HomeFetchRequested());
      context.read<ContentBloc>().add(const ContentFetchRequested());
      context.read<CourseBloc>().add(const CourseFetchRequested());
      context.read<LeaderboardBloc>().add(const LeaderboardFetchRequested());
      context.read<NotificationBloc>().add(const NotificationFetchRequested());
      context.read<MyContentBloc>().add(const MyContentFetchRequested());
      context.read<CommunityBloc>().add(const CommunityFetchRequested());
      _maybeShowEthicsNotice(context.read<AuthBloc>().state);
    });
  }

  Future<void> _maybeShowEthicsNotice(AuthState state) async {
    if (_ethicsDialogShown) return;
    if (state is AuthAuthenticated &&
        state.showEthicsNotice &&
        !state.mustChangePassword &&
        mounted) {
      _ethicsDialogShown = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const EthicsNoticeDialog(),
      );
      if (mounted) {
        context.read<AuthBloc>().add(AuthEthicsNoticeAcknowledged());
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(noticeMessage: state.message),
            ),
            (route) => false,
          );
        } else if (state is AuthAuthenticated && state.showEthicsNotice) {
          _maybeShowEthicsNotice(state);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.darkForest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'GrowHub',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Karyawan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Saved articles shortcut
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: AppColors.darkForest),
              tooltip: 'Artikel Tersimpan',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SavedContentsScreen(),
                  ),
                );
              },
            ),

            // Notification Bell with Badge
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                int unread = 0;
                if (state is NotificationLoaded) {
                  unread = state.unreadCount;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: AppColors.darkForest),
                      tooltip: 'Notifikasi',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeTab(onNavigateTab: _onTabSelected),
            const FeedTab(),
            const CoursesScreen(),
            const LeaderboardScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.feed_outlined),
              activeIcon: Icon(Icons.feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Belajar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Peringkat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
