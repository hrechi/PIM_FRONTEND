import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quiz_model.dart';
import '../models/skill_certification_model.dart';
import '../services/skill_certification_api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/app_drawer.dart';

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
