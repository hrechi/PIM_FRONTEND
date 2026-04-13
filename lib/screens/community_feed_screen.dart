import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/community_models.dart';
import '../services/api_service.dart';
import '../services/community_service.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityService _service = CommunityService();
  final List<CommunityPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadPosts();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await ApiService.getCurrentUserId();
    if (mounted) {
      setState(() => _currentUserId = userId);
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _service.fetchPosts(limit: 25);
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCreatePostSheet() async {
    final created = await showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(service: _service),
    );

    if (created != null) {
      setState(() {
        _posts.insert(0, created);
      });
    }
  }

  Future<void> _reactPost(CommunityPost post, String reactionType) async {
    try {
      final data = await _service.reactToPost(post.id, reactionType);
      final updated = post.copyWith(
        likesCount: (data['likesCount'] as num?)?.toInt() ?? post.likesCount,
        dislikesCount:
            (data['dislikesCount'] as num?)?.toInt() ?? post.dislikesCount,
        myReaction: data['myReaction']?.toString(),
      );
      _replacePost(updated);
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _vote(CommunityPost post, String optionId) async {
    try {
      final data = await _service.vote(post.id, optionId);
      final options = (data['options'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CommunityPollOption.fromJson)
          .toList();

      final updated = post.copyWith(
        pollOptions: options,
        totalVotes: (data['totalVotes'] as num?)?.toInt() ?? post.totalVotes,
        myVoteOptionId: data['myVoteOptionId']?.toString(),
      );
      _replacePost(updated);
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _openEditPostSheet(CommunityPost post) async {
    final updated = await showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPostSheet(service: _service, post: post),
    );

    if (updated != null) {
      _replacePost(updated);
      _showSnack('Post updated successfully');
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });
      _showSnack('Post deleted');
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _openComments(CommunityPost post) async {
    final count = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.52,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => _CommentsSheet(
          post: post,
          service: _service,
          scrollController: scrollController,
          currentUserId: _currentUserId,
        ),
      ),
    );

    if (count != null) {
      _replacePost(post.copyWith(commentsCount: count));
    }
  }

  void _replacePost(CommunityPost updated) {
    final index = _posts.indexWhere((post) => post.id == updated.id);
    if (index == -1) return;
    setState(() {
      _posts[index] = updated;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
        actions: [
          IconButton(
            onPressed: _openCreatePostSheet,
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F8EE), Color(0xFFF8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.error_outline, size: 52, color: Colors.red.shade400),
                        const SizedBox(height: 12),
                        Center(child: Text(_error!)),
                        const SizedBox(height: 12),
                        Center(
                          child: FilledButton(
                            onPressed: _loadPosts,
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: _posts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _ComposerCard(onTap: _openCreatePostSheet);
                        }

                        final post = _posts[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PostCard(
                            post: post,
                            currentUserId: _currentUserId,
                            onLike: () => _reactPost(post, 'LIKE'),
                            onDislike: () => _reactPost(post, 'DISLIKE'),
                            onComment: () => _openComments(post),
                            onVote: (optionId) => _vote(post, optionId),
                            onEdit: () => _openEditPostSheet(post),
                            onDelete: () => _deletePost(post),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ComposerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF0E7A43), Color(0xFF46B37A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.campaign_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share an update or start a vote with farmers',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    color: Color(0xFF0E7A43),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final String? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;
  final ValueChanged<String> onVote;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PostCard({
    required this.post,
    this.currentUserId,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    required this.onVote,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundImage: _authorAvatar(post.author),
                  child: (post.author.profilePicture ?? '').isEmpty
                      ? Text(
                          _initials(post.author.name),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${post.author.farmName ?? 'Local farm'} • ${_timeAgo(post.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (post.isVote)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF7EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Vote',
                      style: TextStyle(
                        color: Color(0xFF0E7A43),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (currentUserId != null && currentUserId == post.author.id) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(height: 1.4)),
            if (post.imagePath != null && post.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  _resolveMediaUrl(post.imagePath!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.black12,
                    height: 220,
                    child: const Center(child: Text('Image unavailable')),
                  ),
                ),
              ),
            ],
            if (post.isVote) ...[
              const SizedBox(height: 12),
              _PollBox(post: post, onVote: onVote),
            ],
            const SizedBox(height: 8),
            const Divider(height: 16),
            Row(
              children: [
                _ActionChip(
                  icon: post.myReaction == 'LIKE' ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: '${post.likesCount}',
                  selected: post.myReaction == 'LIKE',
                  onTap: onLike,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: post.myReaction == 'DISLIKE' ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: '${post.dislikesCount}',
                  selected: post.myReaction == 'DISLIKE',
                  onTap: onDislike,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentsCount}',
                  selected: false,
                  onTap: onComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _authorAvatar(CommunityAuthor author) {
    final path = author.profilePicture;
    if (path == null || path.isEmpty) return null;
    return NetworkImage(_resolveMediaUrl(path));
  }
}

class _PollBox extends StatelessWidget {
  final CommunityPost post;
  final ValueChanged<String> onVote;

  const _PollBox({required this.post, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final totalVotes = post.totalVotes <= 0 ? 1 : post.totalVotes;
    final isClosed = post.pollEndsAt != null && post.pollEndsAt!.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCEEAD7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.pollQuestion ?? 'Community vote',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...post.pollOptions.map((option) {
            final ratio = option.votesCount / totalVotes;
            final selected = post.myVoteOptionId == option.id;
            return InkWell(
              onTap: isClosed ? null : () => onVote(option.id),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? const Color(0xFF0E7A43) : Colors.black12,
                  ),
                  color: selected ? const Color(0xFFE8F5EC) : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(option.text)),
                        Text('${option.votesCount}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE4EEE8),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        selected ? const Color(0xFF0E7A43) : const Color(0xFF7DBA93),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 2),
          Text(
            '$totalVotes vote${totalVotes > 1 ? 's' : ''}${isClosed ? ' • Closed' : ''}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? const Color(0xFFE8F5EC) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? const Color(0xFF0E7A43) : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? const Color(0xFF0E7A43) : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final CommunityService service;

  const _CreatePostSheet({required this.service});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentCtrl = TextEditingController();
  final _pollQuestionCtrl = TextEditingController();
  final List<TextEditingController> _pollOptionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isVote = false;
  bool _submitting = false;
  DateTime? _pollEndsAt;
  XFile? _selectedImage;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _pollQuestionCtrl.dispose();
    for (final controller in _pollOptionCtrls) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (image == null) return;
    setState(() => _selectedImage = image);
  }

  void _setVoteMode(bool enabled) {
    setState(() {
      _isVote = enabled;
      if (enabled) {
        _selectedImage = null;
      } else {
        _pollQuestionCtrl.clear();
        _pollEndsAt = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: now.add(const Duration(days: 2)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;
    setState(() {
      _pollEndsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (!_isVote && content.isEmpty) {
      _showSnack('Write something before posting');
      return;
    }

    final options = _pollOptionCtrls
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (_isVote) {
      if (_pollQuestionCtrl.text.trim().isEmpty) {
        _showSnack('Add a poll question');
        return;
      }
      if (options.length < 2) {
        _showSnack('Add at least 2 poll options');
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final created = await widget.service.createPost(
        content: _isVote ? null : content,
        imagePath: _isVote ? null : _selectedImage?.path,
        pollQuestion: _isVote ? _pollQuestionCtrl.text.trim() : null,
        pollOptions: _isVote ? options : null,
        pollEndsAt: _isVote ? _pollEndsAt : null,
      );

      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      _showSnack(e.toString());
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Create Community Post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'What is happening in your farm today?',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!_isVote) ...[
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(_selectedImage == null ? 'Add Photo' : 'Photo Selected'),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            selected: !_isVote,
                            onSelected: (_) => _setVoteMode(false),
                            label: const Text('Normal Post'),
                          ),
                          FilterChip(
                            selected: _isVote,
                            onSelected: (_) => _setVoteMode(true),
                            label: const Text('Vote Post'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!_isVote && _selectedImage != null && !kIsWeb) ...[
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: InkWell(
                          onTap: () => setState(() => _selectedImage = null),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: !_isVote
                      ? const SizedBox.shrink()
                      : Column(
                          key: const ValueKey('vote-mode'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            TextField(
                              controller: _pollQuestionCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Poll question',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._pollOptionCtrls.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextField(
                                  controller: entry.value,
                                  decoration: InputDecoration(
                                    hintText: 'Option ${entry.key + 1}',
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _pollOptionCtrls.length >= 6
                                      ? null
                                      : () {
                                          setState(() {
                                            _pollOptionCtrls.add(TextEditingController());
                                          });
                                        },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add option'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _pickEndDate,
                                  icon: const Icon(Icons.timer_outlined),
                                  label: Text(
                                    _pollEndsAt == null
                                        ? 'Set end date'
                                        : DateFormat('dd MMM, HH:mm').format(_pollEndsAt!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_outlined),
                    label: Text(_submitting ? 'Posting...' : 'Publish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  final ScrollController scrollController;
  final String? currentUserId;

  const _CommentsSheet({
    required this.post,
    required this.service,
    required this.scrollController,
    this.currentUserId,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _inputCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  List<CommunityComment> _comments = [];
  CommunityComment? _replyTarget;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final comments = await widget.service.fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await widget.service.addComment(
        postId: widget.post.id,
        content: text,
        parentCommentId: _replyTarget?.id,
      );

      _inputCtrl.clear();
      _replyTarget = null;
      await _load();
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _reactComment(String commentId, String type) async {
    try {
      final data = await widget.service.reactToComment(commentId, type);
      _comments = _updateCommentNode(
        _comments,
        commentId,
        likesCount: (data['likesCount'] as num?)?.toInt(),
        dislikesCount: (data['dislikesCount'] as num?)?.toInt(),
        myReaction: data['myReaction']?.toString(),
      );
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _editComment(CommunityComment comment) async {
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => _EditCommentDialog(
        initialContent: comment.content,
      ),
    );

    if (newContent == null || newContent.trim().isEmpty) return;

    try {
      final updated = await widget.service.updateComment(
        commentId: comment.id,
        content: newContent,
      );

      // Update the comment in the list
      _comments = _updateCommentContent(_comments, comment.id, updated.content);
      if (mounted) setState(() {});
      _showSnack('Comment updated');
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.service.deleteComment(comment.id);
      _comments = _removeCommentFromTree(_comments, comment.id);
      if (mounted) setState(() {});
      _showSnack('Comment deleted');
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  List<CommunityComment> _updateCommentContent(
    List<CommunityComment> source,
    String id,
    String newContent,
  ) {
    return source.map((comment) {
      if (comment.id == id) {
        return comment.copyWith(content: newContent);
      }

      if (comment.replies.isEmpty) {
        return comment;
      }

      return comment.copyWith(
        replies: _updateCommentContent(comment.replies, id, newContent),
      );
    }).toList();
  }

  List<CommunityComment> _removeCommentFromTree(
    List<CommunityComment> source,
    String id,
  ) {
    final result = <CommunityComment>[];
    
    for (final comment in source) {
      if (comment.id == id) {
        continue; // Skip this comment
      }

      if (comment.replies.isEmpty) {
        result.add(comment);
      } else {
        final updatedReplies = _removeCommentFromTree(comment.replies, id);
        result.add(comment.copyWith(replies: updatedReplies));
      }
    }
    
    return result;
  }

  List<CommunityComment> _updateCommentNode(
    List<CommunityComment> source,
    String id, {
    int? likesCount,
    int? dislikesCount,
    String? myReaction,
  }) {
    return source.map((comment) {
      if (comment.id == id) {
        return comment.copyWith(
          likesCount: likesCount,
          dislikesCount: dislikesCount,
          myReaction: myReaction,
        );
      }

      if (comment.replies.isEmpty) {
        return comment;
      }

      return comment.copyWith(
        replies: _updateCommentNode(
          comment.replies,
          id,
          likesCount: likesCount,
          dislikesCount: dislikesCount,
          myReaction: myReaction,
        ),
      );
    }).toList();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        'Comments (${_comments.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context, _comments.length),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 4),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                        ? const Center(child: Text('No comments yet'))
                        : ListView(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: _comments
                                .map(
                                  (comment) => _CommentItem(
                                    comment: comment,
                                    currentUserId: widget.currentUserId,
                                    onLike: (commentId) => _reactComment(commentId, 'LIKE'),
                                    onDislike: (commentId) => _reactComment(commentId, 'DISLIKE'),
                                    onReply: (target) => setState(() => _replyTarget = target),
                                    onEdit: (comment) => _editComment(comment),
                                    onDelete: (comment) => _deleteComment(comment),
                                  ),
                                )
                                .toList(),
                          ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyTarget != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F7F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${_replyTarget!.author.name}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _replyTarget = null),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'Write a comment...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendComment,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommunityComment comment;
  final String? currentUserId;
  final ValueChanged<String> onLike;
  final ValueChanged<String> onDislike;
  final ValueChanged<CommunityComment> onReply;
  final ValueChanged<CommunityComment>? onEdit;
  final ValueChanged<CommunityComment>? onDelete;

  const _CommentItem({
    required this.comment,
    this.currentUserId,
    required this.onLike,
    required this.onDislike,
    required this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBubble(comment, false),
          ...comment.replies.map((reply) => _buildReply(reply)),
        ],
      ),
    );
  }

  Widget _buildReply(CommunityComment reply) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 6),
      child: _buildBubble(reply, true),
    );
  }

  Widget _buildBubble(CommunityComment node, bool isReply) {
    final likeSelected = node.myReaction == 'LIKE';
    final dislikeSelected = node.myReaction == 'DISLIKE';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isReply ? const Color(0xFFF8FBF9) : const Color(0xFFF2F7F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                node.author.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(node.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const Spacer(),
              if (currentUserId != null && currentUserId == node.author.id)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) {
                      onEdit!(node);
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!(node);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(node.content),
          const SizedBox(height: 6),
          Row(
            children: [
              _CommentReactionPill(
                icon: Icons.thumb_up_alt_outlined,
                count: node.likesCount,
                selected: likeSelected,
                selectedColor: const Color(0xFF0E7A43),
                onTap: () => onLike(node.id),
              ),
              const SizedBox(width: 10),
              _CommentReactionPill(
                icon: Icons.thumb_down_alt_outlined,
                count: node.dislikesCount,
                selected: dislikeSelected,
                selectedColor: const Color(0xFF8A5A1B),
                onTap: () => onDislike(node.id),
              ),
              if (node.id == comment.id) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => onReply(node),
                  child: Text(
                    'Reply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentReactionPill extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _CommentReactionPill({
    required this.icon,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? selectedColor.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(
            color: selected ? selectedColor.withValues(alpha: 0.35) : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? selectedColor : Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? selectedColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPostSheet extends StatefulWidget {
  final CommunityService service;
  final CommunityPost post;

  const _EditPostSheet({required this.service, required this.post});

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late TextEditingController _contentCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      _showSnack('Please enter some content');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updated = await widget.service.updatePost(
        postId: widget.post.id,
        content: content,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Post',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentCtrl,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditCommentDialog extends StatefulWidget {
  final String initialContent;

  const _EditCommentDialog({required this.initialContent});

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Comment'),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Edit your comment...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final newContent = _controller.text.trim();
            if (newContent.isNotEmpty) {
              Navigator.pop(context, newContent);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'F';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

String _resolveMediaUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  final normalized = path.startsWith('/') ? path : '/$path';
  return '${ApiService.mediaBaseUrl}$normalized';
}

String _timeAgo(DateTime value) {
  final duration = DateTime.now().difference(value);
  if (duration.inMinutes < 1) return 'just now';
  if (duration.inMinutes < 60) return '${duration.inMinutes}m';
  if (duration.inHours < 24) return '${duration.inHours}h';
  if (duration.inDays < 7) return '${duration.inDays}d';
  return DateFormat('dd MMM').format(value);
}
