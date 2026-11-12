import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/content_model.dart';
import 'badge_chip.dart';

class ContentCard extends StatelessWidget {
  final ContentModel content;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;

  const ContentCard({
    super.key,
    required this.content,
    required this.onTap,
    this.onLike,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final authorName = content.author?.name ?? 'Karyawan';
    final department = content.author?.department ?? 'GrowHub';
    final timeStr = DateFormatter.timeAgo(content.publishedAt ?? content.createdAt);
    final categoryName = content.category?.name ?? 'Umum';

    // Check if media has an image
    String? imageUrl;
    for (var m in content.media) {
      if (m.type == 'image' && m.url != null && m.url!.isNotEmpty) {
        imageUrl = m.url;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Author & Category
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$department • $timeStr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BadgeChip(
                    label: categoryName,
                    fontSize: 11,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Snippet
              Text(
                content.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              // Optional image preview
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action buttons & counts
              Row(
                children: [
                  // Like
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            content.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: content.isLiked
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${content.likesCount}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: content.isLiked
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Comments
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${content.commentsCount}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Views
                  Row(
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${content.viewsCount}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bookmark / Save
                  IconButton(
                    icon: Icon(
                      content.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: content.isSaved
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
