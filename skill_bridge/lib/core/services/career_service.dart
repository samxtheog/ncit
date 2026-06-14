import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class CareerRoadmap {
  final String career;
  final String overview;
  final String matchReason;
  final List<RoadmapStep> steps;
  final List<ProCon> pros;
  final List<ProCon> cons;
  final String salaryRange;
  final String jobDemand;
  final List<String> topSkillsNeeded;

  const CareerRoadmap({
    required this.career,
    required this.overview,
    required this.matchReason,
    required this.steps,
    required this.pros,
    required this.cons,
    required this.salaryRange,
    required this.jobDemand,
    required this.topSkillsNeeded,
  });

  factory CareerRoadmap.fromJson(Map<String, dynamic> json) => CareerRoadmap(
        career: json['career'] as String,
        overview: json['overview'] as String,
        matchReason: json['matchReason'] as String,
        steps: (json['steps'] as List)
            .map((s) => RoadmapStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        pros: (json['pros'] as List)
            .map((p) => ProCon.fromJson(p as Map<String, dynamic>))
            .toList(),
        cons: (json['cons'] as List)
            .map((c) => ProCon.fromJson(c as Map<String, dynamic>))
            .toList(),
        salaryRange: json['salaryRange'] as String,
        jobDemand: json['jobDemand'] as String,
        topSkillsNeeded:
            List<String>.from(json['topSkillsNeeded'] as List),
      );

  Map<String, dynamic> toJson() => {
        'career': career,
        'overview': overview,
        'matchReason': matchReason,
        'steps': steps.map((s) => s.toJson()).toList(),
        'pros': pros.map((p) => p.toJson()).toList(),
        'cons': cons.map((c) => c.toJson()).toList(),
        'salaryRange': salaryRange,
        'jobDemand': jobDemand,
        'topSkillsNeeded': topSkillsNeeded,
      };
}

class RoadmapStep {
  final int step;
  final String title;
  final String duration;
  final String description;
  final List<String> resources;

  const RoadmapStep({
    required this.step,
    required this.title,
    required this.duration,
    required this.description,
    required this.resources,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) => RoadmapStep(
        step: json['step'] as int,
        title: json['title'] as String,
        duration: json['duration'] as String,
        description: json['description'] as String,
        resources: List<String>.from(json['resources'] as List),
      );

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'duration': duration,
        'description': description,
        'resources': resources,
      };
}

class ProCon {
  final String title;
  final String description;

  const ProCon({required this.title, required this.description});

  factory ProCon.fromJson(Map<String, dynamic> json) => ProCon(
        title: json['title'] as String,
        description: json['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}

class RoadmapResult {
  final bool isSuccess;
  final CareerRoadmap? roadmap;
  final String? errorMessage;
  final bool fromCache;

  const RoadmapResult._({
    required this.isSuccess,
    this.roadmap,
    this.errorMessage,
    this.fromCache = false,
  });

  factory RoadmapResult.success(CareerRoadmap roadmap,
          {bool fromCache = false}) =>
      RoadmapResult._(
          isSuccess: true, roadmap: roadmap, fromCache: fromCache);

  factory RoadmapResult.failure(String message) =>
      RoadmapResult._(isSuccess: false, errorMessage: message);
}

class CareerService {
  static const _timeout = Duration(seconds: 30);

  /// Cache key for a given career title (sanitised for prefs key).
  static String _cacheKey(String careerTitle) =>
      'roadmap_cache_${careerTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

  /// Returns the cached roadmap for [careerTitle], or null if not cached.
  static Future<CareerRoadmap?> getCachedRoadmap(String careerTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey(careerTitle));
      if (json == null) return null;
      return CareerRoadmap.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Clears the cached roadmap for [careerTitle].
  static Future<void> clearCache(String careerTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(careerTitle));
  }

  Future<RoadmapResult> getRoadmap(String careerTitle,
      {bool forceRefresh = false}) async {
    // ── 1. Return from cache if available and not forcing refresh ─────────
    if (!forceRefresh) {
      final cached = await getCachedRoadmap(careerTitle);
      if (cached != null) return RoadmapResult.success(cached, fromCache: true);
    }

    // ── 2. Fetch from AI ───────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      if (token == null) {
        return RoadmapResult.failure('Not logged in. Please sign in again.');
      }

      final body = {
        'careerTitle': careerTitle,
        'faculty':    prefs.getString(AppConstants.keyFaculty)       ?? '',
        'grade':      prefs.getString(AppConstants.keyGrade)         ?? '',
        'interests':  prefs.getStringList(AppConstants.keyInterests) ?? [],
        'skills':     prefs.getStringList(AppConstants.keySkills)    ?? [],
        'goal':       prefs.getString(AppConstants.keyGoal)          ?? '',
      };

      final response = await http
          .post(
            Uri.parse(ApiConstants.careerRoadmap),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final roadmap =
            CareerRoadmap.fromJson(data['roadmap'] as Map<String, dynamic>);

        // ── 3. Persist to cache ────────────────────────────────────────────
        await prefs.setString(
            _cacheKey(careerTitle), jsonEncode(roadmap.toJson()));

        return RoadmapResult.success(roadmap, fromCache: false);
      }

      return RoadmapResult.failure(
          data['message'] as String? ??
              'Failed to generate roadmap. Please try again.');
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        return RoadmapResult.failure('Request timed out. Please try again.');
      }
      if (msg.contains('ClientException') ||
          msg.contains('XMLHttpRequest')) {
        return RoadmapResult.failure(
            'Cannot reach the server. Make sure the backend is running.');
      }
      return RoadmapResult.failure('Something went wrong. Please try again.');
    }
  }

  // ── Learning path ────────────────────────────────────────────────────────

  Future<LearningPathResult> getLearningPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      if (token == null) {
        return LearningPathResult.failure('Not logged in.');
      }

      final response = await http
          .post(
            Uri.parse(ApiConstants.learningPath),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'faculty': prefs.getString(AppConstants.keyFaculty) ?? '',
              'grade': prefs.getString(AppConstants.keyGrade) ?? '',
              'interests':
                  prefs.getStringList(AppConstants.keyInterests) ?? [],
              'skills': prefs.getStringList(AppConstants.keySkills) ?? [],
              'goal': prefs.getString(AppConstants.keyGoal) ?? '',
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final raw = data['learningPath'] as Map<String, dynamic>;
        final steps = (raw['steps'] as List)
            .map((s) =>
                LearningPathStep.fromJson(s as Map<String, dynamic>))
            .toList();
        return LearningPathResult.success(steps);
      }

      return LearningPathResult.failure(
          data['message'] as String? ?? 'Failed to generate learning path.');
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        return LearningPathResult.failure('Request timed out.');
      }
      if (msg.contains('ClientException') || msg.contains('XMLHttpRequest')) {
        return LearningPathResult.failure('Cannot reach server.');
      }
      return LearningPathResult.failure('Something went wrong.');
    }
  }
}

// ── Learning path models ──────────────────────────────────────────────────────

class LearningPathStep {
  final String title;
  final String subtitle;

  const LearningPathStep({required this.title, required this.subtitle});

  factory LearningPathStep.fromJson(Map<String, dynamic> json) =>
      LearningPathStep(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
      );

  Map<String, dynamic> toJson() => {'title': title, 'subtitle': subtitle};
}

class LearningPathResult {
  final bool isSuccess;
  final List<LearningPathStep>? steps;
  final String? errorMessage;

  const LearningPathResult._(
      {required this.isSuccess, this.steps, this.errorMessage});

  factory LearningPathResult.success(List<LearningPathStep> steps) =>
      LearningPathResult._(isSuccess: true, steps: steps);

  factory LearningPathResult.failure(String msg) =>
      LearningPathResult._(isSuccess: false, errorMessage: msg);
}

// ── Career suggestions ────────────────────────────────────────────────────────

class CareerSuggestion {
  final String title;
  final int match;
  final String description;
  final String category;

  const CareerSuggestion({
    required this.title,
    required this.match,
    required this.description,
    required this.category,
  });

  factory CareerSuggestion.fromJson(Map<String, dynamic> json) =>
      CareerSuggestion(
        title: json['title'] as String,
        match: (json['match'] as num).toInt(),
        description: json['description'] as String,
        category: json['category'] as String? ?? 'other',
      );
}

class SuggestionsResult {
  final bool isSuccess;
  final List<CareerSuggestion>? careers;
  final String? errorMessage;
  final bool fromCache;

  const SuggestionsResult._({
    required this.isSuccess,
    this.careers,
    this.errorMessage,
    this.fromCache = false,
  });

  factory SuggestionsResult.success(List<CareerSuggestion> careers,
          {bool fromCache = false}) =>
      SuggestionsResult._(isSuccess: true, careers: careers, fromCache: fromCache);

  factory SuggestionsResult.failure(String msg) =>
      SuggestionsResult._(isSuccess: false, errorMessage: msg);
}

extension CareerServiceSuggestions on CareerService {
  static const String _suggestionsCacheKey = 'career_suggestions_cache';

  Future<SuggestionsResult> getSuggestions({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Return cache unless forced
    if (!forceRefresh) {
      final cached = prefs.getString(_suggestionsCacheKey);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List)
              .map((e) => CareerSuggestion.fromJson(e as Map<String, dynamic>))
              .toList();
          return SuggestionsResult.success(list, fromCache: true);
        } catch (_) {}
      }
    }

    final token = prefs.getString(AppConstants.keyAuthToken);
    if (token == null) return SuggestionsResult.failure('Not logged in.');

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.careerSuggestions),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'faculty':   prefs.getString(AppConstants.keyFaculty)       ?? '',
              'grade':     prefs.getString(AppConstants.keyGrade)         ?? '',
              'interests': prefs.getStringList(AppConstants.keyInterests) ?? [],
              'skills':    prefs.getStringList(AppConstants.keySkills)    ?? [],
              'goal':      prefs.getString(AppConstants.keyGoal)          ?? '',
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final careers = (data['careers'] as List)
            .map((e) => CareerSuggestion.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache it
        await prefs.setString(
          _suggestionsCacheKey,
          jsonEncode(careers.map((c) => {
            'title': c.title,
            'match': c.match,
            'description': c.description,
            'category': c.category,
          }).toList()),
        );

        return SuggestionsResult.success(careers, fromCache: false);
      }

      return SuggestionsResult.failure(
          data['message'] as String? ?? 'Failed to load career suggestions.');
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        return SuggestionsResult.failure('Request timed out. Please try again.');
      }
      if (msg.contains('ClientException') || msg.contains('XMLHttpRequest')) {
        return SuggestionsResult.failure('Cannot reach the server.');
      }
      return SuggestionsResult.failure('Something went wrong. Please try again.');
    }
  }
}

// ── AI Interest suggestions ───────────────────────────────────────────────────

class InterestOption {
  final String name;
  final String iconKey; // category string from backend

  const InterestOption({required this.name, required this.iconKey});

  factory InterestOption.fromJson(Map<String, dynamic> json) => InterestOption(
        name: json['name'] as String,
        iconKey: json['icon'] as String? ?? 'other',
      );
}

class InterestSuggestionsResult {
  final bool isSuccess;
  final List<InterestOption>? interests;
  final String? errorMessage;

  const InterestSuggestionsResult._({
    required this.isSuccess,
    this.interests,
    this.errorMessage,
  });

  factory InterestSuggestionsResult.success(List<InterestOption> interests) =>
      InterestSuggestionsResult._(isSuccess: true, interests: interests);

  factory InterestSuggestionsResult.failure(String msg) =>
      InterestSuggestionsResult._(isSuccess: false, errorMessage: msg);
}

Future<InterestSuggestionsResult> fetchInterestSuggestions({
  required String faculty,
  required String grade,
  required String token,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse(ApiConstants.careerInterests),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'faculty': faculty, 'grade': grade}),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      final interests = (data['interests'] as List)
          .map((e) => InterestOption.fromJson(e as Map<String, dynamic>))
          .toList();
      return InterestSuggestionsResult.success(interests);
    }

    return InterestSuggestionsResult.failure(
        data['message'] as String? ?? 'Failed to load interest suggestions.');
  } on Exception catch (e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) {
      return InterestSuggestionsResult.failure('Request timed out.');
    }
    if (msg.contains('ClientException') || msg.contains('XMLHttpRequest')) {
      return InterestSuggestionsResult.failure('Cannot reach the server.');
    }
    return InterestSuggestionsResult.failure('Something went wrong.');
  }
}
