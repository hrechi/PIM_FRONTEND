import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/short_video.dart';
import '../providers/shorts_provider.dart';
import '../services/shorts_service.dart';
import '../theme/color_palette.dart';

/// Full-screen vertical-swipe YouTube Shorts feed for agriculture content.
/// Uses WebView to load actual YouTube Shorts URLs (bypasses embed restrictions).
class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 1.0,
  );
  int _currentPage = 0;
  bool _isMuted = false; // Videos play with sound by default

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final provider = context.read<ShortsProvider>();
    if (provider.videos.isEmpty) {
      provider.loadShorts();
      provider.loadCategories();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);

    // Prefetch more when near end
    final provider = context.read<ShortsProvider>();
    if (index >= provider.videos.length - 3 && provider.hasMore) {
      provider.loadMore();
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ShortsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.videos.isEmpty) {
            return _buildLoading();
          }
          if (provider.error != null && provider.videos.isEmpty) {
            return _buildError(provider);
          }
          if (provider.videos.isEmpty) {
            return _buildEmpty();
          }
          return Stack(
            children: [
              // ── Video PageView ─────────────────────
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const ClampingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                itemCount: provider.videos.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final video = provider.videos[index];
                  return _ShortVideoPage(
                    video: video,
                    isActive: index == _currentPage,
                    isMuted: _isMuted,
                    onToggleMute: _toggleMute,
                  );
                },
              ),

              // ── Top bar: back + mute + category chips ─
              _buildTopBar(provider),

              // ── Loading more indicator ─────────────
              if (provider.isLoadingMore)
                const Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(ShortsProvider provider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Farm Reels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Mute / Unmute toggle
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.agriculture, color: Colors.white70, size: 24),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: provider.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = provider.categories[index];
                  final isActive =
                      cat.toLowerCase() == provider.activeCategory.toLowerCase();
                  return GestureDetector(
                    onTap: () => provider.changeCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColorPalette.fieldFreshStart
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColorPalette.fieldFreshStart
                              : Colors.white30,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColorPalette.fieldFreshStart),
          SizedBox(height: 16),
          Text(
            'Loading Farm Reels...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ShortsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadShorts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.fieldFreshStart,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, color: Colors.white54, size: 64),
          SizedBox(height: 16),
          Text(
            'No shorts available',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Individual short video page — WebView loading actual YT Shorts URL
// ════════════════════════════════════════════════════════════════
class _ShortVideoPage extends StatefulWidget {
  final ShortVideo video;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const _ShortVideoPage({
    required this.video,
    required this.isActive,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  State<_ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<_ShortVideoPage> {
  WebViewController? _controller;
  bool _isLoaded = false;
  bool _isPaused = false;
  bool _showOverlay = true;
  bool _showHeart = false;
  bool _isLiked = false;
  bool _showControls = false;   // Instagram-style center controls
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initWebView();
    }
  }

  @override
  void didUpdateWidget(covariant _ShortVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _isPaused = false;
      _initWebView();
    } else if (!widget.isActive && oldWidget.isActive) {
      setState(() {
        _controller = null;
        _isLoaded = false;
        _isPaused = false;
      });
    }

    // Handle mute toggle from parent
    if (widget.isActive &&
        _controller != null &&
        widget.isMuted != oldWidget.isMuted) {
      _applyMuteState();
    }
  }

  void _applyMuteState() {
    if (_controller == null) return;
    _controller!.runJavaScript('''
      (function() {
        var v = document.querySelector('video');
        if (v) { v.muted = ${widget.isMuted}; }
      })();
    ''');
  }

  void _initWebView() {
    final ctrl = WebViewController();
    ctrl.setJavaScriptMode(JavaScriptMode.unrestricted);
    ctrl.setBackgroundColor(Colors.black);
    ctrl.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
            // Inject CSS to hide YouTube UI chrome, then set audio state
            ctrl.runJavaScript('''
              (function() {
                var style = document.createElement('style');
                style.textContent = \`
                  ytm-mobile-topbar-renderer,
                  .page-header-banner,
                  ytm-comment-section-renderer,
                  ytm-item-section-renderer,
                  .slim-video-metadata-header-modern,
                  .related-chips-slot-wrapper,
                  ytm-engagement-panel-section-list-renderer,
                  .watch-below-the-player,
                  .music-button,
                  #menu-button,
                  .slim-video-action-bar-renderer,
                  ytm-slim-video-action-bar-renderer,
                  .player-controls-top,
                  .EndScreenModule,
                  ytm-reel-multi-format-link-renderer,
                  /* Hide YouTube native mute / volume buttons */
                  .volume-button,
                  .mute-button,
                  button[aria-label="Mute"],
                  button[aria-label="Unmute"],
                  .ytShortsLockupViewModelHostEndpoint,
                  .player-controls-bottom,
                  .reel-player-overlay-actions,
                  [class*="mute"],
                  [class*="volume"],
                  .player-controls-content {
                    display: none !important;
                    pointer-events: none !important;
                  }
                  body {
                    overflow: hidden !important;
                    background: black !important;
                  }
                \`;
                document.head.appendChild(style);

                // Force unmute + autoplay, keep retrying to beat YT default mute
                var unmuteTries = 0;
                function setup() {
                  var v = document.querySelector('video');
                  if (v) {
                    v.muted = ${widget.isMuted};
                    v.volume = 1.0;
                    v.play();
                    // YouTube may re-mute after a short delay, so keep forcing
                    if (unmuteTries < 10) {
                      unmuteTries++;
                      setTimeout(setup, 300);
                    }
                  } else {
                    setTimeout(setup, 500);
                  }
                }
                setup();

                // Also click any native mute buttons YouTube may show
                function clickUnmute() {
                  var btns = document.querySelectorAll(
                    'button[aria-label=\"Unmute\"], button[aria-label=\"Mute\"], .volume-button, .mute-button, [class*=\"mute\"]'
                  );
                  btns.forEach(function(b) {
                    var v = document.querySelector('video');
                    if (v && v.muted) b.click();
                  });
                }
                setTimeout(clickUnmute, 1000);
                setTimeout(clickUnmute, 2000);
              })();
            ''');
          }
        },
        onNavigationRequest: (request) {
          if (request.url.contains('youtube.com') ||
              request.url.contains('googlevideo.com') ||
              request.url.contains('google.com')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ),
    );
    ctrl.setUserAgent(
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    );
    ctrl.loadRequest(
      Uri.parse('https://www.youtube.com/shorts/${widget.video.videoId}'),
    );
    setState(() => _controller = ctrl);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    super.dispose();
  }

  /// Toggle center controls overlay (Instagram Reels style)
  void _toggleControls() {
    if (_showControls) {
      // Hide controls immediately on second tap
      _controlsTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      // Show controls + auto-hide after 4s
      setState(() => _showControls = true);
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _togglePause() {
    if (_controller == null) return;
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _controller!.runJavaScript(
        '(function(){ var v=document.querySelector("video"); if(v) v.pause(); })();',
      );
    } else {
      _controller!.runJavaScript(
        '(function(){ var v=document.querySelector("video"); if(v) v.play(); })();',
      );
    }
    // Reset auto-hide timer after interacting
    _startControlsTimer();
  }

  void _seekBy(int seconds) {
    if (_controller == null) return;
    _controller!.runJavaScript(
      '(function(){ var v=document.querySelector("video"); if(v) v.currentTime += $seconds; })();',
    );
    _startControlsTimer();
  }

  void _handleDoubleTap() {
    setState(() {
      _isLiked = true;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(videoId: widget.video.videoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── WebView Player or Thumbnail ──────
        if (widget.isActive && _controller != null)
          WebViewWidget(controller: _controller!)
        else
          _buildThumbnail(),

        // ── Loading indicator ────────────────
        if (!_isLoaded && widget.isActive)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColorPalette.fieldFreshStart,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.video.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Tap detection: single tap = show/hide controls, double tap = heart ──
        Positioned(
          left: 0,
          right: 60,
          top: 120,
          bottom: 120,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleControls,
            onDoubleTap: _handleDoubleTap,
            child: const SizedBox.expand(),
          ),
        ),

        // ── Instagram-style center controls (play/pause + ±5s) ──
        if (_showControls)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withOpacity(0.25),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Rewind 5s ──
                      _ControlCircleButton(
                        icon: Icons.replay_5,
                        size: 40,
                        onTap: () => _seekBy(-5),
                      ),
                      const SizedBox(width: 32),
                      // ── Play / Pause ──
                      _ControlCircleButton(
                        icon: _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 56,
                        onTap: _togglePause,
                      ),
                      const SizedBox(width: 32),
                      // ── Forward 5s ──
                      _ControlCircleButton(
                        icon: Icons.forward_5,
                        size: 40,
                        onTap: () => _seekBy(5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Double-tap heart animation ───────
        if (_showHeart)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value > 0.8 ? 2.0 - value * 1.25 : 1.0,
                  child: Transform.scale(
                    scale: value * 1.5,
                    child: child,
                  ),
                );
              },
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 100,
              ),
            ),
          ),

        // ── Bottom info overlay ──────────────
        if (_showOverlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 80, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.video.channelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.video.formattedViewCount} views',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('\u2022',
                            style: TextStyle(color: Colors.white38)),
                        const SizedBox(width: 8),
                        Text(
                          widget.video.timeAgo,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Right side action buttons ────────
        if (_showOverlay)
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                _ActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: widget.video.formattedLikeCount,
                  color: _isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() => _isLiked = !_isLiked);
                  },
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.comment,
                  label: widget.video.formattedCommentCount,
                  color: Colors.white,
                  onTap: _showComments,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: Colors.white,
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Icon(Icons.keyboard_arrow_up,
                        color: Colors.white.withOpacity(0.4), size: 28),
                    Text(
                      'Swipe',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.video.thumbnailUrl.isNotEmpty)
            Image.network(
              widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          const Center(
            child: Icon(Icons.play_circle_outline,
                color: Colors.white38, size: 64),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Comments Bottom Sheet
// ════════════════════════════════════════════════════════════════
class _CommentsSheet extends StatefulWidget {
  final String videoId;

  const _CommentsSheet({required this.videoId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final ShortsService _service = ShortsService();
  final ScrollController _scrollController = ScrollController();
  List<ShortComment> _comments = [];
  String? _nextPageToken;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _nextPageToken != null) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    try {
      final response = await _service.fetchComments(videoId: widget.videoId);
      if (mounted) {
        setState(() {
          _comments = response.comments;
          _nextPageToken = response.nextPageToken;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || _nextPageToken == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _service.fetchComments(
        videoId: widget.videoId,
        pageToken: _nextPageToken,
      );
      if (mounted) {
        setState(() {
          _comments.addAll(response.comments);
          _nextPageToken = response.nextPageToken;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle bar + header ──────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  Text(
                    '(${_comments.length})',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // ── Comment list ─────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColorPalette.fieldFreshStart,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : _comments.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    color: Colors.white30, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount:
                                _comments.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _comments.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColorPalette.fieldFreshStart,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              return _CommentTile(comment: _comments[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Single comment tile
// ════════════════════════════════════════════════════════════════
class _CommentTile extends StatelessWidget {
  final ShortComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white12,
            backgroundImage: comment.authorProfileUrl.isNotEmpty
                ? NetworkImage(comment.authorProfileUrl)
                : null,
            child: comment.authorProfileUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white30, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                if (comment.likeCount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likeCount}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Circular control button (play/pause, ±5s)
// ════════════════════════════════════════════════════════════════
class _ControlCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlCircleButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size * 0.35),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Reusable action button (like, comment, share)
// ════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32, shadows: const [
            Shadow(color: Colors.black54, blurRadius: 8),
          ]),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
