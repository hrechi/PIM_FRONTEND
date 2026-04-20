import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quiz_model.dart';
import '../models/skill_certification_model.dart';
import '../providers/auth_provider.dart';
import '../services/skill_certification_api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/app_drawer.dart';

enum CertificateSortOption { titleAsc, titleDesc, durationDesc }

class SkillCertificationScreen extends StatefulWidget {
  const SkillCertificationScreen({super.key});

  @override
  State<SkillCertificationScreen> createState() =>
      _SkillCertificationScreenState();
}

class _SkillCertificationScreenState extends State<SkillCertificationScreen> {
  final SkillCertificationApiService _service = SkillCertificationApiService();
  final Set<String> _expandedLessons = <String>{};

  List<SkillTrainingPath> _paths = [];
  SkillPathDetail? _selectedPath;
  SkillProgressOverview? _overview;

  bool _isLoading = true;
  bool _isLoadingPath = false;
  String? _error;

  String _selectedLanguage = 'en-US';

  List<QuizQuestion> _quizQuestions = [];
  SkillLessonItem? _quizLesson;
  int _quizIndex = 0;
  List<String?> _quizAnswers = [];
  bool _isSubmittingQuiz = false;
  bool _isGeneratingQuiz = false;
  SkillQuizSubmissionResult? _lastResult;
  final TextEditingController _certificateSearchController =
      TextEditingController();
  String _certificateSearchQuery = '';
  CertificateSortOption _certificateSort = CertificateSortOption.titleAsc;

  final List<Map<String, String>> _languageOptions = const [
    {'code': 'en-US', 'label': 'English'},
    {'code': 'fr-FR', 'label': 'Francais'},
    {'code': 'ar', 'label': 'Arabic'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({String? preferredPathId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        _service.getPaths(),
        _service.getProgressOverview(),
      ]);

      final paths = responses[0] as List<SkillTrainingPath>;
      final overview = responses[1] as SkillProgressOverview;

      if (paths.isEmpty) {
        if (!mounted) return;
        setState(() {
          _paths = [];
          _overview = overview;
          _selectedPath = null;
          _isLoading = false;
        });
        return;
      }

      final selectedId = preferredPathId ?? _selectedPath?.id ?? paths.first.id;
      final pathToOpen = paths.any((path) => path.id == selectedId)
          ? selectedId
          : paths.first.id;

      final details = await _service.getPathDetails(pathToOpen);

      if (!mounted) return;
      setState(() {
        _paths = paths;
        _overview = overview;
        _selectedPath = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load training paths: $e';
      });
    }
  }

  Future<void> _openPath(String pathId) async {
    if (_selectedPath?.id == pathId) return;

    setState(() {
      _isLoadingPath = true;
      _error = null;
    });

    try {
      final details = await _service.getPathDetails(pathId);
      if (!mounted) return;
      setState(() {
        _selectedPath = details;
        _isLoadingPath = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPath = false;
        _error = 'Could not open selected path: $e';
      });
    }
  }

  Future<void> _startLessonQuiz(SkillLessonItem lesson) async {
    setState(() {
      _isGeneratingQuiz = true;
      _error = null;
      _lastResult = null;
    });

    try {
      final payload = await _service.generateLessonQuiz(
        lesson.id,
        languageCode: _selectedLanguage,
        questionCount: 6,
      );

      if (!mounted) return;
      setState(() {
        _quizLesson = lesson;
        _quizQuestions = payload.questions;
        _quizAnswers = List<String?>.filled(payload.questions.length, null);
        _quizIndex = 0;
        _isGeneratingQuiz = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeneratingQuiz = false;
        _error = 'Quiz generation failed: $e';
      });
    }
  }

  Future<void> _submitQuiz() async {
    final lesson = _quizLesson;
    if (lesson == null || _quizQuestions.isEmpty) return;

    final answers = _quizAnswers.map((answer) => answer ?? '').toList();

    setState(() {
      _isSubmittingQuiz = true;
      _error = null;
    });

    try {
      final result = await _service.submitLessonQuiz(
        lesson.id,
        languageCode: _selectedLanguage,
        questions: _quizQuestions,
        answers: answers,
      );

      if (!mounted) return;
      setState(() {
        _isSubmittingQuiz = false;
        _lastResult = result;
        _quizQuestions = [];
        _quizAnswers = [];
        _quizIndex = 0;
      });

      await _loadDashboard(preferredPathId: _selectedPath?.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmittingQuiz = false;
        _error = 'Failed to submit quiz: $e';
      });
    }
  }

  void _exitQuizMode() {
    setState(() {
      _quizLesson = null;
      _quizQuestions = [];
      _quizAnswers = [];
      _quizIndex = 0;
      _isSubmittingQuiz = false;
    });
  }

  @override
  void dispose() {
    _certificateSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF2F5EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _quizLesson == null ? 'Skill Certification' : 'Competency Quiz',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColorPalette.charcoalGreen,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadDashboard(preferredPathId: _selectedPath?.id),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quizLesson != null && _quizQuestions.isNotEmpty) {
      return _buildQuizMode();
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE7DB)),
            ),
            child: const TabBar(
              labelColor: Color(0xFF114932),
              unselectedLabelColor: Color(0xFF6F8076),
              indicatorColor: Color(0xFF114932),
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Training Paths'),
                Tab(text: 'My Certificates'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_buildTrainingTab(), _buildMyCertificatesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingTab() {
    return RefreshIndicator(
      onRefresh: () => _loadDashboard(preferredPathId: _selectedPath?.id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 14),
          _buildLanguagePicker(),
          const SizedBox(height: 14),
          _buildPathCarousel(),
          const SizedBox(height: 14),
          if (_isLoadingPath)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildLessonPanel(),
          if (_isGeneratingQuiz)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            _buildResultBanner(_lastResult!),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(_error!),
          ],
        ],
      ),
    );
  }

  Widget _buildMyCertificatesTab() {
    final completedPaths = _paths
        .where(
          (path) =>
              path.status == 'COMPLETED' ||
              path.certificateIssued ||
              path.completionPercent >= 100,
        )
        .toList();

    final query = _certificateSearchQuery.trim().toLowerCase();
    final filtered = completedPaths
        .where(
          (path) =>
              query.isEmpty ||
              path.title.toLowerCase().contains(query) ||
              path.code.toLowerCase().contains(query),
        )
        .toList();

    filtered.sort((a, b) {
      switch (_certificateSort) {
        case CertificateSortOption.titleAsc:
          return a.title.compareTo(b.title);
        case CertificateSortOption.titleDesc:
          return b.title.compareTo(a.title);
        case CertificateSortOption.durationDesc:
          return b.estimatedMinutes.compareTo(a.estimatedMinutes);
      }
    });

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(preferredPathId: _selectedPath?.id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Text(
            'My Certificates',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search, sort, preview and download official Fieldly certificates.',
            style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE6DB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF4B6558)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _certificateSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search certificates...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _certificateSearchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<CertificateSortOption>(
                    value: _certificateSort,
                    items: const [
                      DropdownMenuItem(
                        value: CertificateSortOption.titleAsc,
                        child: Text('A-Z'),
                      ),
                      DropdownMenuItem(
                        value: CertificateSortOption.titleDesc,
                        child: Text('Z-A'),
                      ),
                      DropdownMenuItem(
                        value: CertificateSortOption.durationDesc,
                        child: Text('Longest'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _certificateSort = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _buildErrorBanner(
              completedPaths.isEmpty
                  ? 'No certificates yet. Complete a path to unlock one.'
                  : 'No certificates match your search.',
            )
          else
            ...filtered.map(_buildCertificateCard),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(SkillTrainingPath path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102E24), Color(0xFF18553E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9C06A), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFFF2D47F),
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fieldly Certificate of Competency',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF8F4E3),
                  ),
                ),
              ),
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFFF2D47F),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            path.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Completion: ${path.completionPercent}%  •  Lessons: ${path.completedLessons}/${path.totalLessons}',
            style: AppTextStyles.bodySmall(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFC26A).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD9C06A).withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    'Issued by FIELDLY',
                    style: AppTextStyles.caption(
                      color: const Color(0xFFF5E7B1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openCertificatePreview(path),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9C06A),
                  foregroundColor: const Color(0xFF1D2A1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openCertificatePreview(SkillTrainingPath path) {
    final recipientName = _getRecipientName();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificatePreviewScreen(
          path: path,
          recipientName: recipientName,
          onDownload: () => _downloadCertificatePdf(path),
        ),
      ),
    );
  }

  String _getRecipientName() {
    final auth = context.read<AuthProvider>();
    final rawName = auth.user?.name.trim() ?? '';
    return rawName.isNotEmpty ? rawName : 'Fieldly User';
  }

  Future<void> _downloadCertificatePdf(SkillTrainingPath path) async {
    setState(() {
      _error = null;
    });

    try {
      final recipientName = _getRecipientName();
      final issuedAt = DateTime.now();
      final certificateId =
          'FLD-${path.code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}-${issuedAt.millisecondsSinceEpoch.toString().substring(7)}';

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#D5B968'),
                  width: 2,
                ),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      color: PdfColor.fromHex('#0F3B2E'),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'FIELDLY',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'OFFICIAL CERTIFICATE',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#F7E6A7'),
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 34),
                    pw.Center(
                      child: pw.Text(
                        'Certificate of Completion',
                        style: pw.TextStyle(
                          fontSize: 34,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1D2F26'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Center(
                      child: pw.Text(
                        'This certifies that',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColor.fromHex('#4A5A52'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        recipientName,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#123D2F'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Center(
                      child: pw.Text(
                        'has successfully completed the Fieldly certification path:',
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: PdfColor.fromHex('#4A5A52'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        path.title,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F3B2E'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 28),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#D6E0DA'),
                        ),
                        color: PdfColor.fromHex('#F7FAF8'),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Completion: ${path.completionPercent}%'),
                          pw.Text(
                            'Lessons Completed: ${path.completedLessons}/${path.totalLessons}',
                          ),
                          pw.Text('Certificate ID: $certificateId'),
                          pw.Text(
                            'Issued Date: ${issuedAt.year}-${issuedAt.month.toString().padLeft(2, '0')}-${issuedAt.day.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                    pw.Spacer(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 170,
                              height: 1,
                              color: PdfColor.fromHex('#A4B5AD'),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('Fieldly Learning Authority'),
                          ],
                        ),
                        pw.Text(
                          'fieldly.ai',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0F3B2E'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final bytes = await doc.save();
      final safeCode = path.code.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
      final filename =
          'fieldly_certificate_${safeCode}_${issuedAt.millisecondsSinceEpoch}.pdf';

      final docsDir = await getApplicationDocumentsDirectory();
      final appFile = File('${docsDir.path}/$filename');
      await appFile.writeAsBytes(bytes, flush: true);

      File outputFile = appFile;

      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          try {
            final downloadFile = File('${downloadDir.path}/$filename');
            await downloadFile.writeAsBytes(bytes, flush: true);
            outputFile = downloadFile;
          } catch (_) {
            // Fall back to app documents if direct Download write is unavailable.
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certificate saved as PDF: ${outputFile.path}'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              Share.shareXFiles([
                XFile(outputFile.path),
              ], text: 'My official Fieldly certificate');
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to generate certificate PDF: $e';
      });
    }
  }

  Widget _buildHeroCard() {
    final overview = _overview;
    final overall = overview?.overallPercent ?? 0;
    final completedPaths = overview?.completedPaths ?? 0;
    final totalPaths = overview?.totalPaths ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3D2E), Color(0xFF177245), Color(0xFF1E8A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Command Center',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Micro-lessons + role-ready competency checks for your farm team.',
            style: AppTextStyles.bodyMedium(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildHeroStat('Overall', '$overall%'),
              const SizedBox(width: 10),
              _buildHeroStat('Paths', '$completedPaths/$totalPaths'),
              const SizedBox(width: 10),
              _buildHeroStat('Certs', '${overview?.certificatesUnlocked ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, color: Color(0xFF157347)),
          const SizedBox(width: 8),
          Text(
            'Quiz Language',
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.charcoalGreen,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              items: _languageOptions
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry['code'],
                      child: Text(entry['label'] ?? entry['code'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedLanguage = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCarousel() {
    if (_paths.isEmpty) {
      return _buildErrorBanner('No skill path is available yet.');
    }

    return SizedBox(
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _paths.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final path = _paths[index];
          final selected = path.id == _selectedPath?.id;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openPath(path.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 260,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _hexToColor(path.gradientStart, const Color(0xFF14753D)),
                    _hexToColor(path.gradientEnd, const Color(0xFF29A55F)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 1.6,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFromName(path.icon), color: Colors.white, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    path.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${path.completionPercent}% complete',
                    style: AppTextStyles.bodySmall(
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: path.completionPercent / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFEDB5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonPanel() {
    final path = _selectedPath;
    if (path == null) {
      return _buildErrorBanner('Select a path to view its lessons.');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E7DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A3D2C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            path.description,
            style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                '${path.difficulty} level',
                const Color(0xFFE8F6EE),
                const Color(0xFF13643B),
              ),
              _chip(
                '${path.estimatedMinutes} min',
                const Color(0xFFE7F3FF),
                const Color(0xFF0B5FA5),
              ),
              _chip(
                '${path.completedLessons}/${path.totalLessons} lessons',
                const Color(0xFFFFF3D8),
                const Color(0xFF8A5B00),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...path.lessons.map(_buildLessonCard),
        ],
      ),
    );
  }

  Widget _buildLessonCard(SkillLessonItem lesson) {
    final isExpanded = _expandedLessons.contains(lesson.id);
    final completed = lesson.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFE7DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: AppTextStyles.h4(color: const Color(0xFF234433)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(lesson.status).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lesson.status.replaceAll('_', ' '),
                  style: AppTextStyles.caption(
                    color: _statusColor(lesson.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lesson.summary,
            style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: lesson.completionPercent / 100,
              backgroundColor: const Color(0xFFE5ECE2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _statusColor(lesson.status),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${lesson.estimatedMinutes} min',
                style: AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
              const SizedBox(width: 10),
              Text(
                'Attempts: ${lesson.attempts}',
                style: AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
              if (lesson.bestScore != null) ...[
                const SizedBox(width: 10),
                Text(
                  'Best: ${lesson.bestScore}%',
                  style: AppTextStyles.caption(
                    color: AppColorPalette.softSlate,
                  ),
                ),
              ],
              const Spacer(),
              if (completed)
                const Icon(Icons.verified_rounded, color: Color(0xFF0B7A52)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedLessons.remove(lesson.id);
                    } else {
                      _expandedLessons.add(lesson.id);
                    }
                  });
                },
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(isExpanded ? 'Hide lesson' : 'Micro lesson'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingQuiz
                      ? null
                      : () => _startLessonQuiz(lesson),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF125E3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.psychology_alt_rounded),
                  label: const Text('Start competency quiz'),
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE3ECE3)),
              ),
              child: Text(
                lesson.microContent,
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.charcoalGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizMode() {
    final lesson = _quizLesson!;
    final question = _quizQuestions[_quizIndex];
    final selected = _quizAnswers[_quizIndex];
    final progress = (_quizIndex + 1) / _quizQuestions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE7DB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: AppTextStyles.h4(color: const Color(0xFF234433)),
                      ),
                    ),
                    Text(
                      '${_quizIndex + 1}/${_quizQuestions.length}',
                      style: AppTextStyles.bodySmall(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: const Color(0xFFE6ECE3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF117544),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  question.question,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF193729),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = question.options[index];
                final isSelected = selected == option;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _quizAnswers[_quizIndex] = option;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFDDF3E7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF177245)
                            : const Color(0xFFDEE8DD),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? const Color(0xFF177245)
                              : const Color(0xFF8B9A90),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.bodyLarge(
                              color: const Color(0xFF20392C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _exitQuizMode,
                child: const Text('Exit'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmittingQuiz
                      ? null
                      : () {
                          if (_quizIndex < _quizQuestions.length - 1) {
                            setState(() {
                              _quizIndex += 1;
                            });
                          } else {
                            _submitQuiz();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF125E3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _isSubmittingQuiz
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _quizIndex < _quizQuestions.length - 1
                              ? 'Next question'
                              : 'Submit competency check',
                        ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _buildErrorBanner(_error!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultBanner(SkillQuizSubmissionResult result) {
    final passColor = result.passed
        ? const Color(0xFF0A6D3E)
        : const Color(0xFF9A3E12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: passColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: passColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.passed ? 'Competency validated' : 'Competency pending',
            style: AppTextStyles.h4(color: passColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Score: ${result.scorePercent}%  •  ${result.correctAnswers}/${result.totalQuestions}',
            style: AppTextStyles.bodyMedium(color: passColor),
          ),
          const SizedBox(height: 6),
          Text(
            result.feedback,
            style: AppTextStyles.bodySmall(color: passColor),
          ),
          if (result.certificateIssued) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF0A6D3E),
                ),
                const SizedBox(width: 6),
                Text(
                  'Path certificate unlocked',
                  style: AppTextStyles.bodyMedium(
                    color: const Color(0xFF0A6D3E),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC4BA)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall(color: const Color(0xFF8D2D1D)),
      ),
    );
  }

  Widget _chip(String label, Color background, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.caption(color: textColor)),
    );
  }

  IconData _iconFromName(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return Icons.content_cut_rounded;
      case 'health_and_safety':
        return Icons.health_and_safety_rounded;
      case 'science':
        return Icons.science_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Color _hexToColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;

    final value = hex.replaceAll('#', '').trim();
    if (value.length != 6) return fallback;

    try {
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF0A6D3E);
      case 'IN_PROGRESS':
        return const Color(0xFF8A5B00);
      default:
        return const Color(0xFF5E6E63);
    }
  }
}

class CertificatePreviewScreen extends StatefulWidget {
  const CertificatePreviewScreen({
    required this.path,
    required this.recipientName,
    required this.onDownload,
    super.key,
  });

  final SkillTrainingPath path;
  final String recipientName;
  final Future<void> Function() onDownload;

  @override
  State<CertificatePreviewScreen> createState() =>
      _CertificatePreviewScreenState();
}

class _CertificatePreviewScreenState extends State<CertificatePreviewScreen> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    await widget.onDownload();

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Certificate Preview',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A2E),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD8BE6F),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF114932),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'FIELDLY',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'OFFICIAL',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF5E2A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Certificate of Completion',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F3028),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This certifies that',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(
                        color: const Color(0xFF4D6257),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recipientName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF114932),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'has successfully completed the path',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(
                        color: const Color(0xFF4D6257),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.path.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF163F31),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FAF7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD7E2DC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion: ${widget.path.completionPercent}%',
                            style: AppTextStyles.bodySmall(
                              color: const Color(0xFF274438),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lessons: ${widget.path.completedLessons}/${widget.path.totalLessons}',
                            style: AppTextStyles.bodySmall(
                              color: const Color(0xFF274438),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF114932),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isDownloading ? 'Generating PDF...' : 'Download PDF',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
