/// Model representing a YouTube Short video focused on agriculture
class ShortVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String channelId;
  final String thumbnailUrl;
  final String publishedAt;
  final String viewCount;
  final String likeCount;
  final String commentCount;
  final String description;

  const ShortVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.channelId,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.description,
  });

  factory ShortVideo.fromJson(Map<String, dynamic> json) {
    return ShortVideo(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      channelId: json['channelId'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      viewCount: json['viewCount'] ?? '0',
      likeCount: json['likeCount'] ?? '0',
      commentCount: json['commentCount'] ?? '0',
      description: json['description'] ?? '',
    );
  }

  /// Format large numbers like 1.2M, 3.4K etc.
  String get formattedViewCount => _formatCount(viewCount);
  String get formattedLikeCount => _formatCount(likeCount);
  String get formattedCommentCount => _formatCount(commentCount);

  /// Relative time string like "2 days ago"
  String get timeAgo {
    try {
      final date = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  static String _formatCount(String countStr) {
    final count = int.tryParse(countStr) ?? 0;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Response wrapper for paginated shorts
class ShortsResponse {
  final List<ShortVideo> videos;
  final String? nextPageToken;

  const ShortsResponse({required this.videos, this.nextPageToken});

  factory ShortsResponse.fromJson(Map<String, dynamic> json) {
    return ShortsResponse(
      videos: (json['videos'] as List<dynamic>?)
              ?.map((v) => ShortVideo.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'] as String?,
    );
  }
}

/// Model representing a YouTube comment
class ShortComment {
  final String authorName;
  final String authorProfileUrl;
  final String text;
  final int likeCount;
  final String publishedAt;

  const ShortComment({
    required this.authorName,
    required this.authorProfileUrl,
    required this.text,
    required this.likeCount,
    required this.publishedAt,
  });

  factory ShortComment.fromJson(Map<String, dynamic> json) {
    return ShortComment(
      authorName: json['authorName'] ?? 'Anonymous',
      authorProfileUrl: json['authorProfileUrl'] ?? '',
      text: json['text'] ?? '',
      likeCount: (json['likeCount'] is int)
          ? json['likeCount']
          : int.tryParse(json['likeCount']?.toString() ?? '0') ?? 0,
      publishedAt: json['publishedAt'] ?? '',
    );
  }

  String get timeAgo {
    try {
      final date = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}

/// Response wrapper for paginated comments
class CommentsResponse {
  final List<ShortComment> comments;
  final String? nextPageToken;

  const CommentsResponse({required this.comments, this.nextPageToken});

  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    return CommentsResponse(
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => ShortComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'] as String?,
    );
  }
}
