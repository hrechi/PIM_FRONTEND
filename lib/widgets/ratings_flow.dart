import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_rating.dart';
import '../providers/rating_provider.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

/// Continuous auto-scrolling horizontal marquee of rating cards.
/// Matches the glassmorphism style of the home dashboard.
/// Fully responsive: adapts card size, height, and speed for mobile/tablet/web.
class RatingsFlow extends StatefulWidget {
  const RatingsFlow({super.key});

  @override
  State<RatingsFlow> createState() => _RatingsFlowState();
}

class _RatingsFlowState extends State<RatingsFlow> {
  late final ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isPaused = false;

  // Width of one full copy of the list — set after first layout.
  double _singleCopyWidth = 0;

  static const Duration _tick = Duration(milliseconds: 16); // ~60 fps

  double get _speed => Responsive.isMobile(context) ? 0.6 : 0.9;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(_tick, (_) {
      if (_isPaused || !_scrollController.hasClients) return;
      final current = _scrollController.offset;

      // Once we've scrolled past one full copy, jump back to the start
      // of the second copy — which looks identical, making the loop seamless.
      if (_singleCopyWidth > 0 && current >= _singleCopyWidth) {
        _scrollController.jumpTo(current - _singleCopyWidth);
      } else {
        _scrollController.jumpTo(current + _speed);
      }
    });
  }

  void _pause() {
    _isPaused = true;
  }

  void _resume() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RatingProvider>(
      builder: (context, provider, _) {
        final ratings = provider.ratings;
        if (ratings.isEmpty) return const SizedBox.shrink();

        final isMobile = Responsive.isMobile(context);
        final cardWidth = isMobile ? 180.0 : Responsive.isTablet(context) ? 200.0 : 220.0;
        final cardGap = isMobile ? 10.0 : 12.0;
        final rowHeight = isMobile ? 100.0 : 110.0;
        final headerFontSize = isMobile ? 12.0 : 13.0;

        // Each card occupies cardWidth + gap. Compute one-copy scroll width.
        final itemWidth = cardWidth + cardGap;
        _singleCopyWidth = itemWidth * ratings.length;

        // Always double so the loop has content to jump back into.
        // The scroll resets after exactly one copy, so users never see a repeat.
        final loopList = [...ratings, ...ratings];

        Widget listView = ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
          itemCount: loopList.length,
          itemBuilder: (context, index) => _RatingCard(
            rating: loopList[index],
            width: cardWidth,
            isMobile: isMobile,
          ),
        );

        // On web/desktop: pause on mouse hover.
        // On mobile: pause while finger is down (GestureDetector).
        Widget scrollArea = isMobile || !kIsWeb
            ? GestureDetector(
                onTapDown: (_) => _pause(),
                onTapUp: (_) => _resume(),
                onTapCancel: _resume,
                child: listView,
              )
            : MouseRegion(
                onEnter: (_) => _pause(),
                onExit: (_) => _resume(),
                child: listView,
              );

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 0, isMobile ? 16 : 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 15,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF309448)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What farmers say',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 11),
                          const SizedBox(width: 3),
                          Text(
                            '${ratings.length} review${ratings.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrolling cards ─────────────────────────────────────────
              SizedBox(height: rowHeight, child: scrollArea),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual rating card — glassmorphism style
// ─────────────────────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final AppRating rating;
  final double width;
  final bool isMobile;

  const _RatingCard({
    required this.rating,
    required this.width,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final nameFontSize = isMobile ? 11.0 : 12.0;
    final snippetFontSize = isMobile ? 10.0 : 11.0;
    final avatarRadius = isMobile ? 14.0 : 16.0;
    final starSize = isMobile ? 10.0 : 12.0;
    final hPad = isMobile ? 12.0 : 14.0;
    final vPad = isMobile ? 10.0 : 12.0;

    return Container(
      width: width,
      margin: EdgeInsets.only(right: isMobile ? 10 : 12, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + name + stars
            Row(
              children: [
                _Avatar(name: rating.userName, avatarUrl: rating.avatarUrl, radius: avatarRadius),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _StarRow(stars: rating.stars, size: starSize),
                    ],
                  ),
                ),
              ],
            ),

            // Message snippet
            if (rating.snippet.isNotEmpty) ...[
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                rating.snippet,
                style: TextStyle(
                  color: Colors.white.withAlpha(175),
                  fontSize: snippetFontSize,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const _Avatar({required this.name, this.avatarUrl, required this.radius});

  /// Backend returns relative paths like `/uploads/...` for `profilePicture`.
  /// `NetworkImage` needs a fully-qualified URL — prepend the API base.
  String? _resolvedUrl() {
    final raw = avatarUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = ApiService.mediaBaseUrl;
    return raw.startsWith('/') ? '$base$raw' : '$base/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    final resolved = _resolvedUrl();
    if (resolved != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(resolved),
        backgroundColor: const Color(0xFF309448),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF309448).withAlpha(180),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;
  final double size;

  const _StarRow({required this.stars, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < stars ? const Color(0xFFFFC107) : Colors.white24,
        );
      }),
    );
  }
}
