import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Default host determination
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 maps to the host machine's 127.0.0.1 from the Android emulator
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://127.0.0.1:8000/api';
    }
  }

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String sendChangePasswordOtp = '/auth/change-password/send-otp';
  static const String verifyChangePasswordOtp = '/auth/change-password/verify-otp';
  static const String firstChangePassword = '/auth/first-change-password';

  // Dashboard & Home
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String leaderboard = '/leaderboard';

  // Content & Feed
  static const String categories = '/categories';
  static const String contents = '/contents';
  static const String myContents = '/my/contents';
  static const String mySaved = '/my/saved';
  static String contentDetail(int id) => '/contents/$id';
  static String contentLike(int id) => '/contents/$id/like';
  static String contentSave(int id) => '/contents/$id/save';
  static String contentShare(int id) => '/contents/$id/share';
  static String contentComments(int id) => '/contents/$id/comments';
  static String commentDelete(int commentId) => '/comments/$commentId';

  // Communities
  static const String communities = '/communities';
  static String communityDetail(String slug) => '/communities/$slug';
  static String communityJoin(int id) => '/communities/$id/join';

  // Courses / Learning Center
  static const String courses = '/courses';
  static String courseDetail(String slug) => '/courses/$slug';
  static String courseComplete(int id) => '/courses/$id/complete';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationMarkRead(int id) => '/notifications/$id/read';

  // Profile & Users
  static String userProfile(int id) => '/users/$id';
  static const String profileUpdate = '/profile';
  static const String profileAvatar = '/profile/avatar';
  static const String sendProfilePasswordOtp = '/profile/password/send-otp';
  static const String verifyProfilePasswordOtp = '/profile/password/verify-otp';
  static const String profilePassword = '/profile/password';

  // Support & Policies
  static const String ethicsPolicies = '/ethics-policies';
  static const String faqs = '/support/faqs';
  static const String tickets = '/support/tickets';
}
