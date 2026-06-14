import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class QuizQuestion {
  final int id;
  final String question;
  final Map<String, String> options;
  final String correct;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] as int,
        question: json['question'] as String,
        options: Map<String, String>.from(json['options'] as Map),
        correct: json['correct'] as String,
        explanation: json['explanation'] as String,
      );
}

class Quiz {
  final String subject;
  final String grade;
  final String faculty;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.subject,
    required this.grade,
    required this.faculty,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        subject: json['subject'] as String,
        grade: json['grade'] as String,
        faculty: json['faculty'] as String,
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

class QuizResult {
  final bool isSuccess;
  final Quiz? quiz;
  final String? errorMessage;

  const QuizResult._({required this.isSuccess, this.quiz, this.errorMessage});
  factory QuizResult.success(Quiz quiz) =>
      QuizResult._(isSuccess: true, quiz: quiz);
  factory QuizResult.failure(String msg) =>
      QuizResult._(isSuccess: false, errorMessage: msg);
}

// ── Service ───────────────────────────────────────────────────────────────────

class QuizService {
  static const _timeout = Duration(seconds: 40);

  Future<QuizResult> generateQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      if (token == null) {
        return QuizResult.failure('Not logged in. Please sign in again.');
      }

      final response = await http
          .post(
            Uri.parse(ApiConstants.quizGenerate),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'faculty': prefs.getString(AppConstants.keyFaculty) ?? '',
              'grade': prefs.getString(AppConstants.keyGrade) ?? '',
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final quiz = Quiz.fromJson(data['quiz'] as Map<String, dynamic>);
        return QuizResult.success(quiz);
      }

      return QuizResult.failure(
          data['message'] as String? ?? 'Failed to generate quiz.');
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        return QuizResult.failure('Request timed out. Please try again.');
      }
      if (msg.contains('ClientException') || msg.contains('XMLHttpRequest')) {
        return QuizResult.failure('Cannot reach server. Is the backend running?');
      }
      return QuizResult.failure('Something went wrong. Please try again.');
    }
  }

  /// Add XP points locally AND sync to backend
  static Future<int> addXP(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(AppConstants.keyXP) ?? 0;
    final updated = current + points;
    await prefs.setInt(AppConstants.keyXP, updated);
    return updated;
  }

  static Future<int> getXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyXP) ?? 0;
  }

  /// Check if today's quiz was already completed (new quiz each day)
  static Future<bool> canTakeQuizToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(AppConstants.keyLastQuizDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastDate != today;
  }

  /// Mark quiz done locally and sync all stats to backend
  static Future<void> markQuizDone() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final count = (prefs.getInt(AppConstants.keyQuizCount) ?? 0) + 1;
    await prefs.setString(AppConstants.keyLastQuizDate, today);
    await prefs.setInt(AppConstants.keyQuizCount, count);

    // Sync to backend so stats survive logout/reinstall
    _syncStatsToBackend(prefs, count, today);
  }

  /// Fire-and-forget stats sync — never blocks the UI
  static void _syncStatsToBackend(
      SharedPreferences prefs, int quizCount, String lastQuizDate) async {
    try {
      final token = prefs.getString(AppConstants.keyAuthToken);
      if (token == null) return;
      final xp = prefs.getInt(AppConstants.keyXP) ?? 0;
      await http
          .post(
            Uri.parse(ApiConstants.syncStats),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'xp': xp,
              'quizCount': quizCount,
              'lastQuizDate': lastQuizDate,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Non-critical — local prefs are source of truth until next login
    }
  }
}
