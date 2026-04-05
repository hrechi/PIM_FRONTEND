import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import 'home_screen.dart';

/// Welcome screen with onboarding carousel shown only once
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // List of welcome slides
  final List<WelcomeSlide> _slides = [
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_1.jpg',
      fallbackColor: const Color(0xFF2D5016),
    ),
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_2.jpg',
      fallbackColor: const Color(0xFF3A6B35),
    ),
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_3.jpg',
      fallbackColor: const Color(0xFF4A7C45),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (mounted && _pageController.hasClients) {
      int nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    }
  }

  Future<void> _markWelcomeAsViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasViewedWelcome', true);
  }

  void _handleGetStarted() async {
    await _markWelcomeAsViewed();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView with background images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlideBackground(_slides[index]);
            },
          ),

          // Gradient overlay (dark from bottom to top)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top spacing
                const Spacer(flex: 2),

                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to Fieldly',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h1(color: Colors.white).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI-powered tools for smarter farming',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Dot indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 10,
                        width: _currentPage == index ? 28 : 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: _currentPage == index ? 1.0 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),

                // Get Started button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorPalette.fieldFreshStart,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Get Started',
                        style: AppTextStyles.buttonLarge(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideBackground(WelcomeSlide slide) {
    return Container(
      color: slide.fallbackColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// Try to load asset image; fall back to color
          Image.asset(
            slide.imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: slide.fallbackColor);
            },
          ),
        ],
      ),
    );
  }
}

/// Simple data class for welcome slides
class WelcomeSlide {
  final String imageAsset;
  final Color fallbackColor;

  WelcomeSlide({
    required this.imageAsset,
    required this.fallbackColor,
  });
}
