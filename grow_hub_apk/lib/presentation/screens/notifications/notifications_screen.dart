import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/notification_model.dart';
import '../../../logic/notification/notification_bloc.dart';
import '../../../logic/notification/notification_event.dart';
import '../../../logic/notification/notification_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../feed/content_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () {
              context
                  .read<NotificationBloc>()
                  .add(NotificationMarkAllReadRequested());
            },
            child: const Text('Tandai Dibaca'),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading && state is! NotificationLoaded) {
            return const LoadingIndicator(message: 'Memuat notifikasi...');
          }

          if (state is NotificationError) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: 'Gagal Memuat Notifikasi',
              subtitle: state.message,
              actionText: 'Coba Lagi',
              onAction: () => context
                  .read<NotificationBloc>()
                  .add(const NotificationFetchRequested()),
            );
          }

          if (state is NotificationLoaded) {
            final notifications = state.notifications;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const NotificationFetchRequested(refresh: true));
              },
              child: notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'Tidak Ada Notifikasi',
                      subtitle:
                          'Semua pemberitahuan aktivitas poin, komentar, dan like akan muncul di sini.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 1),
                      itemBuilder: (context, idx) {
                        final item = notifications[idx];
                        return _buildNotificationItem(item, context);
                      },
                    ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      NotificationModel item, BuildContext context) {
    final isUnread = !item.isRead;
    final timeStr = DateFormatter.timeAgo(item.createdAt);

    IconData icon = Icons.notifications;
    Color iconColor = AppColors.primary;

    if (item.type.contains('point') || item.type.contains('award')) {
      icon = Icons.emoji_events;
      iconColor = AppColors.gold;
    } else if (item.type.contains('like')) {
      icon = Icons.favorite;
      iconColor = AppColors.error;
    } else if (item.type.contains('comment')) {
      icon = Icons.chat_bubble;
      iconColor = AppColors.blue;
    } else if (item.type.contains('course')) {
      icon = Icons.school;
      iconColor = AppColors.purple;
    }

    return Container(
      color: isUnread ? AppColors.primaryLight.withOpacity(0.4) : Colors.white,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              item.body,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        onTap: () {
          if (isUnread) {
            context
                .read<NotificationBloc>()
                .add(NotificationMarkReadRequested(item.id));
          }

          // If relates to content, navigate
          if (item.data != null && item.data!.containsKey('content_id')) {
            final contentId = item.data!['content_id'] is int
                ? item.data!['content_id'] as int
                : int.tryParse('${item.data!['content_id']}');
            if (contentId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContentDetailScreen(contentId: contentId),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
