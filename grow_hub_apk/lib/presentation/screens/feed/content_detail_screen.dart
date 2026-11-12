import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/content_repository.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/content_detail/content_detail_bloc.dart';
import '../../../logic/content_detail/content_detail_event.dart';
import '../../../logic/content_detail/content_detail_state.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class ContentDetailScreen extends StatelessWidget {
  final int contentId;

  const ContentDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContentDetailBloc(
        contentRepository: context.read<ContentRepository>(),
      )..add(ContentDetailFetchRequested(contentId)),
      child: const _ContentDetailView(),
    );
  }
}

class _ContentDetailView extends StatefulWidget {
  const _ContentDetailView();

  @override
  State<_ContentDetailView> createState() => _ContentDetailViewState();
}

class _ContentDetailViewState extends State<_ContentDetailView> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      context.read<ContentDetailBloc>().add(ContentDetailCommentSubmitted(text));
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentUserId = 0;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Pengetahuan'),
        actions: [
          BlocBuilder<ContentDetailBloc, ContentDetailState>(
            builder: (context, state) {
              if (state is ContentDetailLoaded) {
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        state.content.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: state.content.isSaved
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      onPressed: () {
                        context
                            .read<ContentDetailBloc>()
                            .add(ContentDetailSaveToggled());
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ContentDetailBloc, ContentDetailState>(
        builder: (context, state) {
          if (state is ContentDetailLoading && state is! ContentDetailLoaded) {
            return const LoadingIndicator(message: 'Memuat artikel...');
          }

          if (state is ContentDetailError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal Memuat Konten',
              subtitle: state.message,
              actionText: 'Kembali',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          if (state is ContentDetailLoaded) {
            final content = state.content;
            final author = content.author;
            final authorName = author?.name ?? 'Karyawan';
            final timeAgo = DateFormatter.formatDate(content.publishedAt ?? content.createdAt);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Community Tag
                        Row(
                          children: [
                            if (content.category != null)
                              BadgeChip(label: content.category!.name),
                            if (content.communityName != null) ...[
                              const SizedBox(width: 8),
                              BadgeChip(
                                label: content.communityName!,
                                backgroundColor: AppColors.purpleLight,
                                textColor: AppColors.purple,
                                icon: Icons.group_work_outlined,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          content.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Author Profile Bar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  authorName.isNotEmpty
                                      ? authorName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${author?.department ?? 'Employee'} • $timeAgo',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Attached Media Images
                        if (content.media.isNotEmpty) ...[
                          for (var m in content.media)
                            if (m.type == 'image' && m.url != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    m.url!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                        ],

                        // Body Article Text
                        Text(
                          content.body,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tags
                        if (content.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: content.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        const Divider(),
                        const SizedBox(height: 12),

                        // Engagement counters & action bar
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .read<ContentDetailBloc>()
                                    .add(ContentDetailLikeToggled());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: content.isLiked
                                    ? AppColors.error
                                    : AppColors.surfaceVariant,
                                foregroundColor: content.isLiked
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: Icon(
                                content.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                              ),
                              label: Text('${content.likesCount} Suka'),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${content.viewsCount} dilihat',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Comments Section Header
                        Row(
                          children: [
                            const Text(
                              'Komentar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${state.comments.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Comments list
                        if (state.comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Belum ada komentar. Jadilah yang pertama memberikan masukan!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.comments.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 18),
                            itemBuilder: (context, idx) {
                              final comment = state.comments[idx];
                              return _buildCommentItem(
                                  comment, currentUserId, context);
                            },
                          ),

                        const SizedBox(height: 30),

                        // Related Articles
                        if (state.related.isNotEmpty) ...[
                          const Text(
                            'Artikel Terkait',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var r in state.related)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.article_outlined,
                                    color: AppColors.primary, size: 20),
                              ),
                              title: Text(
                                r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${r.likesCount} suka • ${DateFormatter.timeAgo(r.publishedAt)}',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ContentDetailScreen(contentId: r.id),
                                  ),
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Comment input box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar atau apresiasi...',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: AppColors.primary),
                          onPressed: state.isPostingComment ? null : _sendComment,
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

  Widget _buildCommentItem(
      CommentModel comment, int currentUserId, BuildContext context) {
    final authorName = comment.user?.name ?? 'Karyawan';
    final isMyComment = comment.userId == currentUserId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.timeAgo(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (isMyComment)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context.read<ContentDetailBloc>().add(
                              ContentDetailCommentDeleteRequested(comment.id),
                            );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                comment.body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
