import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/catalogue_models.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/animal_catalogue_card.dart';
import '../utils/constants.dart';
import '../utils/currency_converter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B5E20);
const _kGreenMid = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFF4CAF50);
const _kGold = Color(0xFFD4A017);
const _kCream = Color(0xFFFAF8F2);
const _kDark = Color(0xFF1A1A1A);

class CatalogueBookScreen extends StatefulWidget {
  final SaleCatalogue catalogue;

  const CatalogueBookScreen({super.key, required this.catalogue});

  @override
  State<CatalogueBookScreen> createState() => _CatalogueBookScreenState();
}

class _CatalogueBookScreenState extends State<CatalogueBookScreen> {
  late final PageController _pageController;
  late final List<CatalogueAnimal> _animals;
  int _currentPage = 0;

  // Total pages = 1 cover + animals + 1 back cover
  int get _totalPages => _animals.length + 2;

  @override
  void initState() {
    super.initState();
    _animals = List.from(widget.catalogue.animals)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Page indicator
          _buildPageIndicator(),
          // Book pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                if (index == 0) return _buildCoverPage(user);
                if (index == _totalPages - 1) return _buildBackCover(user);
                return _buildAnimalPage(_animals[index - 1], index);
              },
            ),
          ),
          // Navigation bar
          _buildNavBar(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white70),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.catalogue.title,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.first_page, color: Colors.white70),
          tooltip: 'Cover',
          onPressed: () => _goTo(0),
        ),
        IconButton(
          icon: const Icon(Icons.last_page, color: Colors.white70),
          tooltip: 'Back cover',
          onPressed: () => _goTo(_totalPages - 1),
        ),
      ],
    );
  }

  // ── Page indicator ────────────────────────────────────────────────────────

  Widget _buildPageIndicator() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (i) {
          final isActive = i == _currentPage;
          return GestureDetector(
            onTap: () => _goTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? _kGold : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Navigation bar ────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    final hasPrev = _currentPage > 0;
    final hasNext = _currentPage < _totalPages - 1;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Prev
          _navBtn(
            icon: Icons.chevron_left,
            label: 'Previous',
            enabled: hasPrev,
            onTap: () => _goTo(_currentPage - 1),
          ),
          const Spacer(),
          // Page label
          Column(
            children: [
              Text(
                _pageLabel(_currentPage),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          // Next
          _navBtn(
            icon: Icons.chevron_right,
            label: 'Next',
            enabled: hasNext,
            onTap: () => _goTo(_currentPage + 1),
            iconOnRight: true,
          ),
        ],
      ),
    );
  }

  String _pageLabel(int index) {
    if (index == 0) return 'Cover';
    if (index == _totalPages - 1) return 'Back Cover';
    return 'Animal ${index} of ${_animals.length}';
  }

  Widget _navBtn({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool iconOnRight = false,
  }) {
    final color = enabled ? Colors.white70 : Colors.white24;
    final children = [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12)),
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(children: iconOnRight ? children.reversed.toList() : children),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COVER PAGE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCoverPage(UserModel? user) {
    final df = DateFormat('MMMM dd, yyyy');
    return _pageWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3B1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(child: _buildBgPattern()),

            // Gold border frame
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _kGold.withAlpha(120), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _kGold.withAlpha(60), width: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo + brand
                  _coverLogo(),
                  const SizedBox(height: 32),

                  // Divider
                  _goldDivider(),
                  const SizedBox(height: 28),

                  // Catalogue title
                  Text(
                    widget.catalogue.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'LIVESTOCK SALES CATALOGUE',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kGold.withAlpha(200),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _goldDivider(),
                  const SizedBox(height: 28),

                  // Stats row
                  _coverStats(),
                  const Spacer(),

                  // Farm info
                  _coverFarmInfo(user),
                  const SizedBox(height: 20),

                  // Date & location
                  _coverMeta(df),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgPattern() {
    return CustomPaint(painter: _PatternPainter());
  }

  Widget _coverLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kGold, width: 2),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text('🌿', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'FIELDLY',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 5,
          ),
        ),
        Text(
          'Smart Farm Management',
          style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(150), letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _goldDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: _kGold.withAlpha(100))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: _kGold, shape: BoxShape.circle),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: _kGold.withAlpha(100))),
      ],
    );
  }

  Widget _coverStats() {
    final count = _animals.length;
    final types = <String>{};
    for (final ca in _animals) {
      if (ca.animal != null) types.add(ca.animal!.animalType);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statBubble('$count', 'Animals'),
        _statBubble('${types.length}', 'Species'),
        if (widget.catalogue.showPrices)
          _statBubble(
            CurrencyConverter.symbol(widget.catalogue.currency),
            widget.catalogue.currency,
          ),
      ],
    );
  }

  Widget _statBubble(String value, String label) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kGold.withAlpha(150), width: 1.5),
            color: Colors.white.withAlpha(15),
          ),
          child: Center(
            child: Text(value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(160), letterSpacing: 1)),
      ],
    );
  }

  Widget _coverFarmInfo(UserModel? user) {
    if (user == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            user.farmName.toUpperCase(),
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          if (user.name.isNotEmpty)
            Text(user.name,
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180))),
          if (user.phone != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 11, color: _kGold.withAlpha(200)),
                const SizedBox(width: 4),
                Text(user.phone!,
                    style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160))),
              ],
            ),
          ],
          if (user.email != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 11, color: _kGold.withAlpha(200)),
                const SizedBox(width: 4),
                Text(user.email!,
                    style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverMeta(DateFormat df) {
    return Column(
      children: [
        if (widget.catalogue.saleDate != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: _kGold.withAlpha(200)),
              const SizedBox(width: 6),
              Text(
                'Sale Date: ${df.format(widget.catalogue.saleDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180)),
              ),
            ],
          ),
        if (widget.catalogue.location != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: _kGold.withAlpha(200)),
              const SizedBox(width: 6),
              Text(
                widget.catalogue.location!,
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Generated ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
          style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(100), letterSpacing: 0.5),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANIMAL PAGE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAnimalPage(CatalogueAnimal ca, int pageIndex) {
    final animal = ca.animal;
    final settings = widget.catalogue.settings;

    return _pageWrapper(
      child: Container(
        color: _kCream,
        child: Column(
          children: [
            // ── Page header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Page number badge
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: _kGreenMid, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '$pageIndex',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal?.name.isNotEmpty == true ? animal!.name : 'Animal #$pageIndex',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kDark),
                        ),
                        if (animal?.tagNumber != null)
                          Text('Tag: ${animal!.tagNumber}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  // Species emoji
                  Text(
                    _speciesEmoji(animal?.animalType ?? ''),
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: animal != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AnimalCatalogueCard(
                        animal: animal,
                        showDetails: settings.showDetails,
                        showPhotos: settings.showPhotos,
                        showHealth: settings.showHealth,
                        showVaccinations: settings.showVaccinations,
                        showProduction: settings.showProduction,
                        showGenetics: settings.showGenetics,
                        showPrices: widget.catalogue.showPrices,
                        currency: widget.catalogue.currency,
                        priceOverride: ca.priceOverride,
                        notes: ca.notes,
                        compactMode: false,
                      ),
                    )
                  : const Center(
                      child: Text('Animal data not available',
                          style: TextStyle(color: Color(0xFF9E9E9E))),
                    ),
            ),

            // ── Page footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.catalogue.title,
                    style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
                  ),
                  const Spacer(),
                  Text(
                    '$pageIndex / ${_animals.length}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BACK COVER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBackCover(UserModel? user) {
    return _pageWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0D3B1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _buildBgPattern()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _kGold.withAlpha(120), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text('FIELDLY',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 5)),
                    const SizedBox(height: 6),
                    Text('Smart Farm Management',
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150), letterSpacing: 2)),
                    const SizedBox(height: 32),
                    _goldDivider(),
                    const SizedBox(height: 24),
                    Text(
                      'Thank you for your interest in our livestock.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200), height: 1.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For inquiries, please contact us.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(150)),
                    ),
                    if (user?.phone != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kGold.withAlpha(80)),
                        ),
                        child: Column(
                          children: [
                            if (user?.phone != null)
                              Text(user!.phone!,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            if (user?.email != null) ...[
                              const SizedBox(height: 4),
                              Text(user!.email!,
                                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _goldDivider(),
                    const SizedBox(height: 20),
                    Text(
                      '${_animals.length} animals listed in this catalogue',
                      style: TextStyle(fontSize: 11, color: _kGold.withAlpha(200), letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Widget _pageWrapper({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  String _speciesEmoji(String type) {
    const map = {'cow': '🐄', 'horse': '🐴', 'sheep': '🐑', 'dog': '🐕'};
    return map[type.toLowerCase()] ?? '🐾';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background pattern painter
// ─────────────────────────────────────────────────────────────────────────────
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(x + spacing / 2, y + spacing / 2), 1.5, paint);
      }
    }

    // Diagonal lines
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.white.withAlpha(5);
    for (double i = -size.height; i < size.width + size.height; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => false;
}
