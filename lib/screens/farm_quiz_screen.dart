import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import '../models/quiz_model.dart';
import '../services/quiz_api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/gradient_container.dart';
import '../providers/parcel_provider.dart';

class FarmQuizScreen extends StatefulWidget {
  final String? parcelId;
  const FarmQuizScreen({super.key, this.parcelId});

  @override
  State<FarmQuizScreen> createState() => _FarmQuizScreenState();
}

class _FarmQuizScreenState extends State<FarmQuizScreen> with TickerProviderStateMixin {
  final QuizApiService _apiService = QuizApiService();
  
  // Quiz State
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  bool _isLoading = true;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _isCorrect = false;
  bool _isFinishing = false;
  
  // Animations
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  
  // Dashboard Stats
  QuizStats? _stats;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardAnimation = CurvedAnimation(parent: _cardController, curve: Curves.easeInOut);
    
    _loadInitialData();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getStats();
      setState(() {
        _stats = stats;
        _streak = stats.streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startNewQuiz() async {
    final parcelId = widget.parcelId;
    
    setState(() {
      _isLoading = true;
      _questions = [];
      _currentIndex = 0;
      _score = 0;
      _isAnswered = false;
      _isFinishing = false;
    });

    try {
      // Configuration per user settings (default 5 for now)
      final questions = await _apiService.generateQuiz(parcelId: parcelId);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      _cardController.forward(from: 0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate quiz. Try again.')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _handleAnswer(String option) {
    if (_isAnswered) return;
    
    final correct = option == _questions[_currentIndex].correctAnswer;
    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      await _cardController.reverse();
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedOption = null;
      });
      _cardController.forward();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() => _isFinishing = true);
    try {
      await _apiService.saveResult(
        score: _score,
        totalQuestions: _questions.length,
        topic: _questions[0].topic,
        parcelId: widget.parcelId,
      );
      await _loadInitialData(); // Refresh stats
      setState(() => _questions = []); // Trigger results view
    } catch (e) {
      // Fallback
      setState(() => _questions = []);
    } finally {
      setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: const Text('Farm Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColorPalette.charcoalGreen,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _questions.isEmpty 
          ? _buildDashboard() 
          : _buildQuizView(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakCard(),
          const SizedBox(height: 20),
          _buildLearningProgress(),
          const SizedBox(height: 20),
          _buildBadgesGrid(),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _startNewQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorPalette.fieldFreshMid,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text(
                  'START NEW QUIZ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return GradientContainer.fieldFresh(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Streak', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text('$_streak Days', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 60),
        ],
      ),
    );
  }

  Widget _buildLearningProgress() {
    final weakAreas = _stats?.weakAreas ?? [];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Learning Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (weakAreas.isEmpty)
              const Text('Doing great! No significant weak areas detected.')
            else ...[
              const Text('Areas needing attention:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: weakAreas.map((area) => Chip(
                  label: Text(area),
                  backgroundColor: AppColorPalette.alertError.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColorPalette.alertError),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final badges = _stats?.badges ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unlocked Badges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (badges.isEmpty)
          const Text('Keep playing to unlock your first badge!', style: TextStyle(color: Colors.grey))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              return _buildBadgeIcon(badges[index]);
            },
          ),
      ],
    );
  }

  Widget _buildBadgeIcon(Badge badge) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColorPalette.fieldFreshMid.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColorPalette.fieldFreshMid, width: 2),
          ),
          child: const Icon(Icons.emoji_events, color: AppColorPalette.fieldFreshMid),
        ),
        const SizedBox(height: 5),
        Text(badge.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(AppColorPalette.fieldFreshMid),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: FadeTransition(
              opacity: _cardAnimation,
              child: ScaleTransition(
                scale: _cardAnimation,
                child: _buildQuestionCard(question),
              ),
            ),
          ),
        ),
        if (_isAnswered)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.charcoalGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _currentIndex == _questions.length - 1 ? 'VIEW RESULTS' : 'NEXT QUESTION',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColorPalette.fieldFreshEnd.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            question.topic.toUpperCase(),
            style: const TextStyle(color: AppColorPalette.fieldFreshEnd, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 15),
        Text(question.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        ...question.options.map((option) => _buildOptionTile(option, question.correctAnswer)),
        if (_isAnswered) ...[
          const SizedBox(height: 20),
          _buildExplanationPanel(question),
        ],
      ],
    );
  }

  Widget _buildOptionTile(String option, String correct) {
    bool selected = _selectedOption == option;
    bool isCorrectOption = option == correct;
    
    Color borderColor = Colors.grey[300]!;
    Color bgColor = Colors.white;
    Widget? trailing;

    if (_isAnswered) {
      if (isCorrectOption) {
        borderColor = AppColorPalette.success;
        bgColor = AppColorPalette.success.withOpacity(0.1);
        trailing = const Icon(Icons.check_circle, color: AppColorPalette.success);
      } else if (selected) {
        borderColor = AppColorPalette.alertError;
        bgColor = AppColorPalette.alertError.withOpacity(0.1);
        trailing = const Icon(Icons.cancel, color: AppColorPalette.alertError);
      }
    } else if (selected) {
      borderColor = AppColorPalette.fieldFreshMid;
      bgColor = AppColorPalette.fieldFreshMid.withOpacity(0.05);
    }

    return GestureDetector(
      onTap: () => _handleAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(option, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationPanel(QuizQuestion question) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('AI Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
              Text(question.aiExplanation, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        if (question.parcelAdvice != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Parcel Advice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      Text(question.parcelAdvice!, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
