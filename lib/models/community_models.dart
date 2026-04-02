class CommunityAuthor {
  final String id;
  final String name;
  final String? profilePicture;
  final String? farmName;

  CommunityAuthor({
    required this.id,
    required this.name,
    this.profilePicture,
    this.farmName,
  });

  factory CommunityAuthor.fromJson(Map<String, dynamic> json) {
    return CommunityAuthor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Farmer',
      profilePicture: json['profilePicture']?.toString(),
      farmName: json['farmName']?.toString(),
    );
  }
}

class CommunityPollOption {
  final String id;
  final String text;
  final int votesCount;
  final int position;

  CommunityPollOption({
    required this.id,
    required this.text,
    required this.votesCount,
    required this.position,
  });

  factory CommunityPollOption.fromJson(Map<String, dynamic> json) {
    return CommunityPollOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      votesCount: (json['votesCount'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityPost {
  final String id;
  final String type;
  final String content;
  final String? imagePath;
  final int commentsCount;
  final int likesCount;
  final int dislikesCount;
  final String? pollQuestion;
  final DateTime? pollEndsAt;
  final DateTime createdAt;
  final CommunityAuthor author;
  final List<CommunityPollOption> pollOptions;
  final int totalVotes;
  final String? myReaction;
  final String? myVoteOptionId;

  CommunityPost({
    required this.id,
    required this.type,
    required this.content,
    required this.imagePath,
    required this.commentsCount,
    required this.likesCount,
    required this.dislikesCount,
    required this.pollQuestion,
    required this.pollEndsAt,
    required this.createdAt,
    required this.author,
    required this.pollOptions,
    required this.totalVotes,
    required this.myReaction,
    required this.myVoteOptionId,
  });

  bool get isVote => type.toUpperCase() == 'VOTE';

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final options = (json['pollOptions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CommunityPollOption.fromJson)
        .toList();

    return CommunityPost(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'STANDARD',
      content: json['content']?.toString() ?? '',
      imagePath: json['imagePath']?.toString(),
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikesCount'] as num?)?.toInt() ?? 0,
      pollQuestion: json['pollQuestion']?.toString(),
      pollEndsAt: json['pollEndsAt'] != null
          ? DateTime.tryParse(json['pollEndsAt'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      author: CommunityAuthor.fromJson(
        (json['author'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      pollOptions: options,
      totalVotes: (json['totalVotes'] as num?)?.toInt() ??
          options.fold<int>(0, (sum, option) => sum + option.votesCount),
      myReaction: json['myReaction']?.toString(),
      myVoteOptionId: json['myVoteOptionId']?.toString(),
    );
  }

  CommunityPost copyWith({
    int? likesCount,
    int? dislikesCount,
    int? commentsCount,
    String? myReaction,
    List<CommunityPollOption>? pollOptions,
    int? totalVotes,
    String? myVoteOptionId,
  }) {
    return CommunityPost(
      id: id,
      type: type,
      content: content,
      imagePath: imagePath,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      pollQuestion: pollQuestion,
      pollEndsAt: pollEndsAt,
      createdAt: createdAt,
      author: author,
      pollOptions: pollOptions ?? this.pollOptions,
      totalVotes: totalVotes ?? this.totalVotes,
      myReaction: myReaction,
      myVoteOptionId: myVoteOptionId,
    );
  }
}

class CommunityComment {
  final String id;
  final String postId;
  final String? parentCommentId;
  final String content;
  final int likesCount;
  final int dislikesCount;
  final int repliesCount;
  final DateTime createdAt;
  final CommunityAuthor author;
  final String? myReaction;
  final List<CommunityComment> replies;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.parentCommentId,
    required this.content,
    required this.likesCount,
    required this.dislikesCount,
    required this.repliesCount,
    required this.createdAt,
    required this.author,
    required this.myReaction,
    required this.replies,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      parentCommentId: json['parentCommentId']?.toString(),
      content: json['content']?.toString() ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikesCount'] as num?)?.toInt() ?? 0,
      repliesCount: (json['repliesCount'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      author: CommunityAuthor.fromJson(
        (json['author'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      myReaction: json['myReaction']?.toString(),
      replies: (json['replies'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CommunityComment.fromJson)
          .toList(),
    );
  }

  CommunityComment copyWith({
    String? content,
    int? likesCount,
    int? dislikesCount,
    String? myReaction,
    List<CommunityComment>? replies,
  }) {
    return CommunityComment(
      id: id,
      postId: postId,
      parentCommentId: parentCommentId,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      repliesCount: repliesCount,
      createdAt: createdAt,
      author: author,
      myReaction: myReaction,
      replies: replies ?? this.replies,
    );
  }
}
