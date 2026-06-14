import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

/// Thin HTTP wrapper for the SkillBridge auth API.
class AuthService {
  static const _headers = {'Content-Type': 'application/json'};
  static const _timeout = Duration(seconds: 15);

  // ── Register ───────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _post(
      ApiConstants.register,
      {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<AuthResult> googleLogin({required String idToken}) async {
    return _post(
      ApiConstants.googleAuth,
      {'idToken': idToken},
    );
  }

  Future<AuthResult> googleLoginWithProfile({
    required String accessToken,
    required String email,
    required String name,
  }) async {
    return _post(
      ApiConstants.googleAuth,
      {'accessToken': accessToken, 'email': email, 'name': name},
    );
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _post(
      ApiConstants.login,
      {'email': email.trim(), 'password': password},
    );
  }

  // ── Save setup profile ─────────────────────────────────────────────────────

  Future<bool> saveProfile({
    required String token,
    required String faculty,
    required String grade,
    required List<String> interests,
    required List<String> skills,
    required String goal,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.saveProfile),
            headers: {
              ..._headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'faculty': faculty,
              'grade': grade,
              'interests': interests,
              'skills': skills,
              'goal': goal,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        // Persist locally so it's available offline
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyFaculty, faculty);
        await prefs.setString(AppConstants.keyGrade, grade);
        await prefs.setStringList(AppConstants.keyInterests, interests);
        await prefs.setStringList(AppConstants.keySkills, skills);
        await prefs.setString(AppConstants.keyGoal, goal);
        await prefs.setBool(AppConstants.keySetupDone, true);
        return true;
      }
      return false;
    } on Exception {
      return false;
    }
  }

  // ── Sync gamification stats to DB ─────────────────────────────────────────

  Future<void> syncStats({
    required String token,
    required int xp,
    required int quizCount,
    required String lastQuizDate,
  }) async {
    try {
      await http
          .post(
            Uri.parse(ApiConstants.syncStats),
            headers: {
              ..._headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'xp': xp,
              'quizCount': quizCount,
              'lastQuizDate': lastQuizDate,
            }),
          )
          .timeout(_timeout);
      // Fire-and-forget — failure is non-critical, local prefs still valid
    } on Exception {
      // ignore — will sync next time
    }
  }

  // ── Shared POST helper ─────────────────────────────────────────────────────

  Future<AuthResult> _post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final user = data['user'] as Map<String, dynamic>;
        return AuthResult.success(
          token: data['token'] as String,
          name: user['name'] as String,
          email: user['email'] as String,
          userId: user['id'] as String,
          faculty: user['faculty'] as String? ?? '',
          grade: user['grade'] as String? ?? '',
          interests: List<String>.from(user['interests'] as List? ?? []),
          skills: List<String>.from(user['skills'] as List? ?? []),
          goal: user['goal'] as String? ?? '',
          setupDone: user['setupDone'] as bool? ?? false,
          xp: (user['xp'] as num?)?.toInt() ?? 0,
          quizCount: (user['quizCount'] as num?)?.toInt() ?? 0,
          lastQuizDate: user['lastQuizDate'] as String? ?? '',
        );
      }

      return AuthResult.failure(_extractMessage(data));
    } on Exception catch (e) {
      return AuthResult.failure(_friendlyError(e));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _extractMessage(Map<String, dynamic> data) {
    if (data['message'] != null) return data['message'] as String;
    if (data['errors'] != null) {
      final errors = data['errors'] as List<dynamic>;
      if (errors.isNotEmpty) {
        return (errors.first as Map<String, dynamic>)['msg'] as String? ??
            'Validation error.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  String _friendlyError(Exception e) {
    final msg = e.toString();

    // Web throws XMLHttpRequest / ClientException on network failure
    if (msg.contains('XMLHttpRequest') ||
        msg.contains('ClientException') ||
        msg.contains('Failed to fetch') ||
        msg.contains('SocketException') ||
        msg.contains('Connection refused')) {
      return kIsWeb
          ? 'Cannot reach the server. Make sure the backend is running on localhost:5000.'
          : 'Cannot reach the server. Check your connection.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ── Result type ────────────────────────────────────────────────────────────────

class AuthResult {
  final bool isSuccess;
  final String? token;
  final String? name;
  final String? email;
  final String? userId;
  final String? errorMessage;

  // Profile fields from DB
  final String? faculty;
  final String? grade;
  final List<String> interests;
  final List<String> skills;
  final String? goal;
  final bool setupDone;

  // Gamification stats from DB
  final int xp;
  final int quizCount;
  final String lastQuizDate;

  const AuthResult._({
    required this.isSuccess,
    this.token,
    this.name,
    this.email,
    this.userId,
    this.errorMessage,
    this.faculty,
    this.grade,
    this.interests = const [],
    this.skills = const [],
    this.goal,
    this.setupDone = false,
    this.xp = 0,
    this.quizCount = 0,
    this.lastQuizDate = '',
  });

  factory AuthResult.success({
    required String token,
    required String name,
    required String email,
    required String userId,
    String? faculty,
    String? grade,
    List<String> interests = const [],
    List<String> skills = const [],
    String? goal,
    bool setupDone = false,
    int xp = 0,
    int quizCount = 0,
    String lastQuizDate = '',
  }) =>
      AuthResult._(
        isSuccess: true,
        token: token,
        name: name,
        email: email,
        userId: userId,
        faculty: faculty,
        grade: grade,
        interests: interests,
        skills: skills,
        goal: goal,
        setupDone: setupDone,
        xp: xp,
        quizCount: quizCount,
        lastQuizDate: lastQuizDate,
      );

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
