import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class FarmQuizScreen extends StatefulWidget {
  final String? parcelId;
  final String? parcelName;

  const FarmQuizScreen({super.key, this.parcelId, this.parcelName});

  @override
  State<FarmQuizScreen> createState() => _FarmQuizScreenState();
}

class _FarmQuizScreenState extends State<FarmQuizScreen>
    with TickerProviderStateMixin {
  // State
  QuizResult? _quizResult;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _showExplanation = false;
  bool _quizComplete = false;
  List<bool> _answerHistory = [];
  List<BadgeModel> _earnedBadges = [];

  // Animations
  late AnimationController _cardController;
  late AnimationController _feedbackController;
  late AnimationController _streakController;
  late Animation<double> _cardSlide;
  late Animation<double> _feedbackScale;
  late Animation<double> _streakBounce;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _feedbackController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _streakController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _cardSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _feedbackScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut));
    _streakBounce = Tween<double>(begin: 1.0, end: 1.4).animate(
        CurvedAnimation(parent: _streakController, curve: Curves.bounceOut));

    _loadQuiz();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _feedbackController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _streak = 0;
      _bestStreak = 0;
      _showExplanation = false;
      _quizComplete = false;
      _answerHistory = [];
      _earnedBadges = [];
    });

    try {
      final result = await QuizApiService.generateQuiz(parcelId: widget.parcelId);
      setState(() {
        _quizResult = result;
        _isLoading = false;
      });
      _cardController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final question = _quizResult!.questions[_currentIndex];
    final isCorrect = answer == question.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _showExplanation = true;
      if (isCorrect) {
        _score++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _streakController.forward().then((_) => _streakController.reverse());
      } else {
        _streak = 0;
      }
      _answerHistory.add(isCorrect);
    });
    _feedbackController.forward();
  }

  void _nextQuestion() {
    final questions = _quizResult!.questions;
    if (_currentIndex < questions.length - 1) {
      _cardController.reverse().then((_) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
          _showExplanation = false;
        });
        _feedbackController.reset();
        _cardController.forward();
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    // Award badges
    final badges = BadgeModel.allBadges();
    final earned = <BadgeModel>[];
    earned.add(badges.firstWhere((b) => b.id == 'first_quiz')..earned = true);
    if (_score == _quizResult!.questions.length) {
      earned.add(badges.firstWhere((b) => b.id == 'perfect_score')..earned = true);
    }
    setState(() {
      _quizComplete = true;
      _earnedBadges = earned;
    });
  }

  // ── Colors ────────────────────────────────────
  static const _kDeepGreen = Color(0xFF1A4731);
  static const _kGreen = Color(0xFF2ECC71);
  static const _kBg = Color(0xFFF2F5F0);
  static const _kCard = Colors.white;
  static const _kGold = Color(0xFFFFB800);

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kDeepGreen,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🌾 Farm Quiz', style: AppTextStyles.h3(color: Colors.white)),
            if (widget.parcelName != null)
              Text('Parcel: ${widget.parcelName}',
                  style: AppTextStyles.bodySmall(
                      color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
        actions: [
          if (!_isLoading && !_quizComplete)
            TextButton.icon(
              onPressed: _loadQuiz,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
              label: const Text('New Quiz',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _quizComplete
                  ? _buildResults()
                  : _buildQuiz(),
    );
  }

  // ── Loading ───────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: _kGreen.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(children: [
              const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                      color: Color(0xFF2ECC71), strokeWidth: 3)),
              const SizedBox(height: 20),
              Text('🤖 AI Generating Quiz...',
                  style: AppTextStyles.h3(color: _kDeepGreen)),
              const SizedBox(height: 8),
              Text(
                widget.parcelId != null
                    ? 'Personalizing questions for your parcel...'
                    : 'Crafting fresh educational questions...',
                style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Could not load quiz', style: AppTextStyles.h3(color: _kDeepGreen)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: _kDeepGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quiz ──────────────────────────────────────
  Widget _buildQuiz() {
    final questions = _quizResult!.questions;
    final question = questions[_currentIndex];
    final total = questions.length;

    return Column(children: [
      _buildProgressBar(total),
      Expanded(
        child: AnimatedBuilder(
          animation: _cardController,
          builder: (_, child) => Transform.translate(
            offset: Offset(MediaQuery.of(context).size.width * _cardSlide.value, 0),
            child: child,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildScoreRow(),
              const SizedBox(height: 16),
              _buildQuestionCard(question),
              const SizedBox(height: 16),
              ...question.options.map((opt) => _buildOptionTile(opt, question)),
              if (_showExplanation) ...[
                const SizedBox(height: 16),
                _buildExplanationCard(question),
              ],
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ),
      if (_answered) _buildNextButton(),
    ]);
  }

  Widget _buildProgressBar(int total) {
    final progress = (_currentIndex + 1) / total;
    return Container(
      color: _kDeepGreen,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Question ${_currentIndex + 1} of $total',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${(progress * 100).toInt()}% complete',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildScoreRow() {
    return Row(children: [
      _buildStatChip(Icons.star, '$_score pts', _kGold),
      const SizedBox(width: 12),
      ScaleTransition(
        scale: _streakBounce,
        child: _buildStatChip(Icons.local_fire_department,
            '$_streak streak', _streak >= 3 ? Colors.orange : Colors.grey),
      ),
      const Spacer(),
      if (_quizResult?.source == 'ai')
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome, color: Color(0xFF2ECC71), size: 14),
            SizedBox(width: 4),
            Text('AI Generated', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
    ]);
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4731), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _kDeepGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Q${_currentIndex + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          if (widget.parcelId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.landscape, color: Color(0xFFFFB800), size: 12),
                SizedBox(width: 4),
                Text('Parcel-Specific', style: TextStyle(color: Color(0xFFFFB800), fontSize: 11)),
              ]),
            ),
        ]),
        const SizedBox(height: 16),
        Text(question.question,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
      ]),
    );
  }

  Widget _buildOptionTile(String option, QuizQuestion question) {
    Color bgColor = _kCard;
    Color borderColor = Colors.grey.shade200;
    Color textColor = const Color(0xFF1A4731);
    IconData? trailingIcon;

    if (_answered) {
      if (option == question.correctAnswer) {
        bgColor = const Color(0xFFE8F8EF);
        borderColor = _kGreen;
        textColor = const Color(0xFF1A4731);
        trailingIcon = Icons.check_circle;
      } else if (option == _selectedAnswer) {
        bgColor = const Color(0xFFFFF0F0);
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
        trailingIcon = Icons.cancel;
      }
    } else if (option == _selectedAnswer) {
      bgColor = const Color(0xFFE8F8EF);
      borderColor = _kGreen;
    }

    return ScaleTransition(
      scale: _answered && option == question.correctAnswer
          ? _feedbackScale
          : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: () => _selectAnswer(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Text(option,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon,
                  color: option == question.correctAnswer ? _kGreen : Colors.red,
                  size: 22),
          ]),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(QuizQuestion question) {
    final isCorrect = _selectedAnswer == question.correctAnswer;
    return AnimatedOpacity(
      opacity: _showExplanation ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCorrect ? const Color(0xFFE8F8EF) : const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isCorrect ? _kGreen.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(isCorrect ? Icons.check_circle : Icons.info_outline,
                  color: isCorrect ? _kGreen : Colors.orange, size: 20),
              const SizedBox(width: 10),
              Text(isCorrect ? '✅ Correct!' : '❌ Not quite...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCorrect ? const Color(0xFF1A4731) : Colors.red.shade700,
                  )),
            ]),
            const SizedBox(height: 10),
            Text('🧠 Explanation', style: AppTextStyles.bodySmall(color: Colors.grey.shade600)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 4),
            Text(question.aiExplanation,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1A4731))),
          ]),
        ),
        if (question.parcelAdvice.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGold.withValues(alpha: 0.4)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb, color: Color(0xFFFFB800), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Parcel Tip', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFFFB800))),
                  const SizedBox(height: 4),
                  Text(question.parcelAdvice,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1A4731))),
                ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex == _quizResult!.questions.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _nextQuestion,
            icon: Icon(isLast ? Icons.emoji_events : Icons.arrow_forward_rounded),
            label: Text(isLast ? 'See Results' : 'Next Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDeepGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ── Results ───────────────────────────────────
  Widget _buildResults() {
    final total = _quizResult!.questions.length;
    final pct = (_score / total * 100).toInt();
    final Color scoreColor;
    final String message;
    final String emoji;

    if (pct == 100) {
      scoreColor = _kGreen;
      message = 'Perfect Score! You\'re a farming expert!';
      emoji = '🏆';
    } else if (pct >= 80) {
      scoreColor = Colors.green;
      message = 'Excellent work! Keep it up!';
      emoji = '🌟';
    } else if (pct >= 60) {
      scoreColor = Colors.orange;
      message = 'Good effort! A few areas to review.';
      emoji = '🌱';
    } else {
      scoreColor = Colors.red;
      message = 'Keep learning — every farmer improves with practice!';
      emoji = '💪';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),
        // Score circle
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_kDeepGreen, scoreColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: scoreColor.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            Text('$_score/$total',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text('$pct%', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Quiz Complete!', style: AppTextStyles.h2(color: _kDeepGreen)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge(color: AppColorPalette.softSlate)),
        const SizedBox(height: 24),

        // Stats row
        Row(children: [
          _buildResultStat('Best Streak', '🔥 $_bestStreak', Colors.orange),
          const SizedBox(width: 12),
          _buildResultStat('Correct', '✅ $_score', Colors.green),
          const SizedBox(width: 12),
          _buildResultStat('Wrong', '❌ ${total - _score}', Colors.red),
        ]),

        const SizedBox(height: 24),

        // Answer history
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Answer Review', style: AppTextStyles.h3(color: _kDeepGreen)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_answerHistory.length, (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _answerHistory[i] ? const Color(0xFFE8F8EF) : const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _answerHistory[i] ? _kGreen : Colors.red, width: 1.5),
                  ),
                  child: Center(child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _answerHistory[i] ? _kDeepGreen : Colors.red),
                  )),
                ),
              )),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Badges
        if (_earnedBadges.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGold.withValues(alpha: 0.1), _kGold.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🏅 Badges Earned', style: AppTextStyles.h3(color: _kDeepGreen)),
              const SizedBox(height: 12),
              ..._earnedBadges.map((badge) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Text(badge.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(badge.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A4731))),
                    Text(badge.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // Improvement hint
        if (pct < 100)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.school, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Keep Learning!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                const SizedBox(height: 4),
                Text(
                    widget.parcelId != null
                        ? 'Review the parcel tips above and apply them to your fields. Take a new quiz to test your improvement!'
                        : 'Each quiz generates completely new questions. Keep challenging yourself to master all farming topics!',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
              ])),
            ]),
          ),

        const SizedBox(height: 24),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadQuiz,
            icon: const Icon(Icons.refresh),
            label: const Text('New Quiz — Fresh AI Questions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDeepGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDeepGreen,
              side: const BorderSide(color: Color(0xFF1A4731)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }
}
