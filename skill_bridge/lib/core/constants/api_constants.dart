class ApiConstants {
  ApiConstants._();

  // Change this to your machine's IP when testing on a physical device.
  // Use http://10.0.2.2:5000 for Android emulator.
  // Use http://localhost:5000 for iOS simulator / web.
  static const String baseUrl = 'https://sbbe.samx.space/api';

  // Auth endpoints
  static const String register    = '$baseUrl/auth/register';
  static const String login       = '$baseUrl/auth/login';
  static const String me          = '$baseUrl/auth/me';
  static const String saveProfile = '$baseUrl/auth/profile';
  static const String syncStats   = '$baseUrl/auth/stats';

  // Career endpoints
  static const String careerRoadmap       = '$baseUrl/career/roadmap';
  static const String learningPath        = '$baseUrl/career/learning-path';
  static const String careerSuggestions   = '$baseUrl/career/suggestions';
  static const String careerInterests     = '$baseUrl/career/interests';

  // Quiz endpoint
  static const String quizGenerate = '$baseUrl/quiz/generate';

  // Community endpoints
  static const String communityPosts = '$baseUrl/community/posts';

  // PDF endpoints
  static const String pdfUpload = '$baseUrl/pdf/upload';
  static const String pdfList   = '$baseUrl/pdf';

  // AI Chat endpoint
  static const String aiChat      = '$baseUrl/chat';
  static const String aiChatClear = '$baseUrl/chat';

  // Google auth endpoint
  static const String googleAuth = '$baseUrl/auth/google';
}
