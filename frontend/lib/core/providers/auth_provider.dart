import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

// ── Singleton service provider ─────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth state ─────────────────────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? token;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.token,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? token,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      token: token ?? this.token,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  /// Registers a new user. Returns true on success.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _service.register(
      name: name,
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      await _persist(result);
      state = state.copyWith(isLoading: false, token: result.token);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: result.errorMessage,
    );
    return false;
  }

  /// Logs in an existing user. Returns true on success.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _service.login(email: email, password: password);

    if (result.isSuccess) {
      await _persist(result);
      state = state.copyWith(isLoading: false, token: result.token);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: result.errorMessage,
    );
    return false;
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Signs in with Google. Accepts either idToken (Android) or accessToken+profile (web).
  Future<bool> googleLogin({required Map<String, String> tokenData}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final AuthResult result;
    if (tokenData.containsKey('idToken')) {
      result = await _service.googleLogin(idToken: tokenData['idToken']!);
    } else {
      result = await _service.googleLoginWithProfile(
        accessToken: tokenData['accessToken']!,
        email: tokenData['email']!,
        name: tokenData['name']!,
      );
    }
    if (result.isSuccess) {
      await _persist(result);
      state = state.copyWith(isLoading: false, token: result.token);
      return true;
    }
    state = state.copyWith(isLoading: false, errorMessage: result.errorMessage);
    return false;
  }

  // Saves token + user data to SharedPreferences (including profile from DB)
  Future<void> _persist(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyAuthToken, result.token!);
    await prefs.setString(AppConstants.keyUserName, result.name!.split(' ').first);
    await prefs.setString(AppConstants.keyUserId, result.userId!);
    if (result.email != null) {
      await prefs.setString(AppConstants.keyUserEmail, result.email!);
    }

    // Persist profile so the app works offline and routing is correct
    await prefs.setBool(AppConstants.keySetupDone, result.setupDone);
    if (result.faculty != null && result.faculty!.isNotEmpty) {
      await prefs.setString(AppConstants.keyFaculty, result.faculty!);
    }
    if (result.grade != null && result.grade!.isNotEmpty) {
      await prefs.setString(AppConstants.keyGrade, result.grade!);
    }
    if (result.interests.isNotEmpty) {
      await prefs.setStringList(AppConstants.keyInterests, result.interests);
    }
    if (result.skills.isNotEmpty) {
      await prefs.setStringList(AppConstants.keySkills, result.skills);
    }
    if (result.goal != null && result.goal!.isNotEmpty) {
      await prefs.setString(AppConstants.keyGoal, result.goal!);
    }

    // Restore gamification stats from DB.
    // Take the HIGHER of local vs DB value so stats are never lost
    // (handles the case where the user earned XP offline and hasn't synced yet).
    final localXp    = prefs.getInt(AppConstants.keyXP)         ?? 0;
    final localQuiz  = prefs.getInt(AppConstants.keyQuizCount)  ?? 0;
    final dbXp       = result.xp;
    final dbQuiz     = result.quizCount;

    await prefs.setInt(AppConstants.keyXP,         localXp  > dbXp   ? localXp  : dbXp);
    await prefs.setInt(AppConstants.keyQuizCount,  localQuiz > dbQuiz ? localQuiz : dbQuiz);

    // Restore lastQuizDate — keep local if it's today (quiz already done today)
    final localDate = prefs.getString(AppConstants.keyLastQuizDate) ?? '';
    if (localDate.isEmpty && result.lastQuizDate.isNotEmpty) {
      await prefs.setString(AppConstants.keyLastQuizDate, result.lastQuizDate);
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
