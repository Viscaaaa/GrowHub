import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/community_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/home_repository.dart';
import 'data/repositories/leaderboard_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/support_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/community/community_bloc.dart';
import 'logic/content/content_bloc.dart';
import 'logic/course/course_bloc.dart';
import 'logic/home/home_bloc.dart';
import 'logic/leaderboard/leaderboard_bloc.dart';
import 'logic/my_content/my_content_bloc.dart';
import 'logic/notification/notification_bloc.dart';
import 'logic/profile/profile_bloc.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = await LocalStorage.init();

  late final ApiClient apiClient;
  late final AuthBloc authBloc;

  apiClient = ApiClient(
    localStorage: localStorage,
    onUnauthorized: () {
      authBloc.add(AuthLogoutRequested());
    },
  );

  final authRepository = AuthRepository(
    apiClient: apiClient,
    localStorage: localStorage,
  );
  final homeRepository = HomeRepository(apiClient: apiClient);
  final contentRepository = ContentRepository(apiClient: apiClient);
  final communityRepository = CommunityRepository(apiClient: apiClient);
  final courseRepository = CourseRepository(apiClient: apiClient);
  final leaderboardRepository = LeaderboardRepository(apiClient: apiClient);
  final notificationRepository = NotificationRepository(apiClient: apiClient);
  final profileRepository = ProfileRepository(
    apiClient: apiClient,
    localStorage: localStorage,
  );
  final supportRepository = SupportRepository(apiClient: apiClient);

  authBloc = AuthBloc(authRepository: authRepository);

  runApp(
    GrowHubApp(
      localStorage: localStorage,
      apiClient: apiClient,
      authRepository: authRepository,
      homeRepository: homeRepository,
      contentRepository: contentRepository,
      communityRepository: communityRepository,
      courseRepository: courseRepository,
      leaderboardRepository: leaderboardRepository,
      notificationRepository: notificationRepository,
      profileRepository: profileRepository,
      supportRepository: supportRepository,
      authBloc: authBloc,
    ),
  );
}

class GrowHubApp extends StatelessWidget {
  final LocalStorage localStorage;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final HomeRepository homeRepository;
  final ContentRepository contentRepository;
  final CommunityRepository communityRepository;
  final CourseRepository courseRepository;
  final LeaderboardRepository leaderboardRepository;
  final NotificationRepository notificationRepository;
  final ProfileRepository profileRepository;
  final SupportRepository supportRepository;
  final AuthBloc authBloc;

  const GrowHubApp({
    super.key,
    required this.localStorage,
    required this.apiClient,
    required this.authRepository,
    required this.homeRepository,
    required this.contentRepository,
    required this.communityRepository,
    required this.courseRepository,
    required this.leaderboardRepository,
    required this.notificationRepository,
    required this.profileRepository,
    required this.supportRepository,
    required this.authBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: localStorage),
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: homeRepository),
        RepositoryProvider.value(value: contentRepository),
        RepositoryProvider.value(value: communityRepository),
        RepositoryProvider.value(value: courseRepository),
        RepositoryProvider.value(value: leaderboardRepository),
        RepositoryProvider.value(value: notificationRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: supportRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider(
            create: (ctx) => HomeBloc(homeRepository: homeRepository),
          ),
          BlocProvider(
            create: (ctx) => ContentBloc(contentRepository: contentRepository),
          ),
          BlocProvider(
            create: (ctx) =>
                CommunityBloc(communityRepository: communityRepository),
          ),
          BlocProvider(
            create: (ctx) => CourseBloc(courseRepository: courseRepository),
          ),
          BlocProvider(
            create: (ctx) =>
                LeaderboardBloc(leaderboardRepository: leaderboardRepository),
          ),
          BlocProvider(
            create: (ctx) => NotificationBloc(
                notificationRepository: notificationRepository),
          ),
          BlocProvider(
            create: (ctx) =>
                MyContentBloc(contentRepository: contentRepository),
          ),
          BlocProvider(
            create: (ctx) => ProfileBloc(
              profileRepository: profileRepository,
              localStorage: localStorage,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'GrowHub - Edisi Karyawan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
