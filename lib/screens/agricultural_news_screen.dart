import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AgriculturalNewsScreen extends StatefulWidget {
  const AgriculturalNewsScreen({super.key});

  @override
  State<AgriculturalNewsScreen> createState() => _AgriculturalNewsScreenState();
}

class _AgriculturalNewsScreenState extends State<AgriculturalNewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _newsArticles = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String _errorMessage = '';

  final List<Map<String, String>> _categories = [
    {'label': 'All', 'value': 'all', 'icon': 'public'},
    {'label': 'Pests', 'value': 'pests', 'icon': 'bug_report'},
    {'label': 'Market', 'value': 'market', 'icon': 'trending_up'},
    {'label': 'Tech', 'value': 'technology', 'icon': 'psychology'},
    {'label': 'Saved', 'value': 'saved', 'icon': 'bookmarks'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final val = _categories[_tabController.index]['value']!;
        if (val == 'saved') {
          _fetchBookmarks();
        } else {
          _fetchNews(val);
        }
      }
    });
    _fetchNews('all');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews(String category) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isOffline = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmerId = authProvider.user?.id ?? '';

    try {
      final endpoint = '/news?farmerId=$farmerId&category=$category';
      final data = await ApiService.get(endpoint);

      if (mounted) {
        setState(() {
          _newsArticles = data;
          _isLoading = false;
        });
        _cacheNews(data, category);
      }
    } catch (e) {
      if (mounted) {
        _loadCachedNews(category, e.toString());
      }
    }
  }

  Future<void> _fetchBookmarks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isOffline = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmerId = authProvider.user?.id ?? '';

    if (farmerId.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to view saved articles.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await ApiService.get('/bookmarks/$farmerId', withAuth: true);
      if (mounted) {
        setState(() {
          _newsArticles = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load bookmarks: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cacheNews(List<dynamic> data, String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_news_$category', jsonEncode(data));
  }

  Future<void> _loadCachedNews(String category, String originalError) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_news_$category');

    if (cachedData != null && mounted) {
      setState(() {
        _newsArticles = jsonDecode(cachedData);
        _isLoading = false;
        _isOffline = true;
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = 'No connection. Please check your internet.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark(dynamic article) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmerId = authProvider.user?.id ?? '';

    if (farmerId.isEmpty) return;

    try {
      await ApiService.post('/bookmarks', {
        'title': article['title'],
        'description': article['description'],
        'url': article['url'],
        'imageUrl': article['imageUrl'],
        'source': article['source'],
        'farmerId': farmerId,
      }, withAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to bookmarks'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already bookmarked or error'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _removeBookmark(String id) async {
    try {
      await ApiService.delete('/bookmarks/$id', withAuth: true);
      if (mounted) {
        _fetchBookmarks();
      }
    } catch (_) {}
  }

  void _shareArticle(dynamic article) {
    Share.share('${article['title']}\n${article['url']}');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'public': return Icons.public;
      case 'bug_report': return Icons.bug_report;
      case 'trending_up': return Icons.trending_up;
      case 'psychology': return Icons.psychology;
      case 'bookmarks': return Icons.bookmarks;
      default: return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildCategoryTabs()),
          if (_isOffline)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Offline Mode - Showing Cached News', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
            ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
        title: const Text(
          'Agri News',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F5E9), Colors.white],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: () {
              final val = _categories[_tabController.index]['value']!;
              if (val == 'saved') _fetchBookmarks(); else _fetchNews(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: List.generate(_categories.length, (index) {
          final isSelected = _tabController.index == index;
          return AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    if (isSelected) BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_getIcon(_categories[index]['icon']!), color: isSelected ? Colors.white : Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _categories[index]['label']!,
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchNews(_categories[_tabController.index]['value']!),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_newsArticles.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No articles available.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final article = _newsArticles[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
              child: _buildNewsCard(article),
            );
          },
          childCount: _newsArticles.length,
        ),
      ),
    );
  }

  Widget _buildNewsCard(dynamic article) {
    final String title = article['title'] ?? 'No Title';
    final String description = article['description'] ?? '';
    final String imageUrl = article['imageUrl'] ?? '';
    final String source = article['source'] ?? 'Unknown';
    final bool isSavedMode = _categories[_tabController.index]['value'] == 'saved';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(imageUrl),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.5))),
                    child: Text(source.toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E), height: 1.3)),
                  const SizedBox(height: 10),
                  if (description.isNotEmpty)
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildActionButton(
                            icon: isSavedMode ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.green,
                            onTap: () => isSavedMode ? _removeBookmark(article['id']) : _toggleBookmark(article),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(icon: Icons.share_outlined, color: Colors.blue, onTap: () => _shareArticle(article)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _launchUrl(article['url']),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withOpacity(0.2))),
                        ),
                        child: const Text('READ FULL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

  Widget _buildImage(String url) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            )
          : const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
