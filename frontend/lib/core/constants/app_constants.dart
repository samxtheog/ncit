import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Career Guidance';
  static const String appTagline = 'Bridge Your Skills to Your Future';
  static const String appVersion = '1.0.0';

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 28.0;
  static const double radiusCircle = 100.0;

  // Padding
  static const double horizontalPadding = 24.0;
  static const double verticalPadding = 24.0;
  static const double cardPadding = 20.0;

  // Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Prefs Keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyIsLoggedIn     = 'is_logged_in';
  static const String keySetupDone      = 'setup_done';
  static const String keyUserName       = 'user_name';
  static const String keyUserEmail      = 'user_email';
  static const String keyAuthToken      = 'auth_token';
  static const String keyUserId         = 'user_id';

  // Setup profile keys
  static const String keyFaculty = 'user_faculty';
  static const String keyGrade = 'user_grade';
  static const String keyInterests = 'user_interests';
  static const String keySkills = 'user_skills';
  static const String keyGoal = 'user_goal';

  // XP / gamification keys
  static const String keyXP = 'user_xp';
  static const String keyLastQuizDate = 'last_quiz_date';
  static const String keyQuizCount = 'quiz_count';

  // Onboarding — imageUrl uses Unsplash for real illustration photos
  static const List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Find Your Future',
      'description':
          'Discover careers that match your interests and strengths. Build the path that leads to your dream job.',
      'icon': Icons.gps_fixed,
      'imageUrl':
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
      'decorIcons': [
        Icons.business_center,
        Icons.star_rounded,
        Icons.bar_chart_rounded,
        Icons.map_rounded,
      ],
    },
    {
      'title': 'Learn Smarter\nwith AI',
      'description':
          'Upload PDFs, chat with your notes, and understand complex concepts faster with your AI learning assistant.',
      'icon': Icons.smart_toy_rounded,
      'imageUrl':
          'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=600&q=80',
      'decorIcons': [
        Icons.description_rounded,
        Icons.lightbulb_rounded,
        Icons.psychology_rounded,
        Icons.auto_awesome_rounded,
      ],
    },
    {
      'title': 'Earn While\nLearning',
      'description':
          'Complete quizzes, earn XP points, and unlock powerful AI learning tools as you grow your skills.',
      'icon': Icons.emoji_events_rounded,
      'imageUrl':
          'https://images.unsplash.com/photo-1567427017947-545c5f8d16ad?w=600&q=80',
      'decorIcons': [
        Icons.star_rounded,
        Icons.military_tech_rounded,
        Icons.diamond_rounded,
        Icons.rocket_launch_rounded,
      ],
    },
  ];

  // Faculty options — icon is now an IconData
  static const List<Map<String, dynamic>> faculties = [
    {'name': 'Science', 'icon': Icons.science_rounded, 'color': 0xFF4CAF50},
    {'name': 'Management', 'icon': Icons.business_center_rounded, 'color': 0xFF2196F3},
    {'name': 'Humanities', 'icon': Icons.menu_book_rounded, 'color': 0xFFFF9800},
    {'name': 'Education', 'icon': Icons.school_rounded, 'color': 0xFF9C27B0},
    {'name': 'Computer Science', 'icon': Icons.computer_rounded, 'color': 0xFF2196F3},
    {'name': 'Other', 'icon': Icons.auto_awesome_rounded, 'color': 0xFF607D8B},
  ];

  // Grade options — icon is now an IconData
  static const List<Map<String, dynamic>> grades = [
    {'name': 'Grade 8', 'icon': Icons.looks_one_rounded, 'label': '8'},
    {'name': 'Grade 9', 'icon': Icons.looks_two_rounded, 'label': '9'},
    {'name': 'Grade 10', 'icon': Icons.looks_3_rounded, 'label': '10'},
    {'name': 'Grade 11', 'icon': Icons.looks_4_rounded, 'label': '11'},
    {'name': 'Grade 12', 'icon': Icons.looks_5_rounded, 'label': '12'},
    {'name': 'Bachelor', 'icon': Icons.school_rounded, 'label': 'B'},
  ];

  // Interest options
  static const List<String> interests = [
    'Technology',
    'Engineering',
    'Healthcare',
    'Finance',
    'Business',
    'Design',
    'Arts',
    'Law',
    'Education',
    'Marketing',
  ];

  // Skill options
  static const List<String> skills = [
    'Problem Solving',
    'Communication',
    'Leadership',
    'Mathematics',
    'Creativity',
    'Writing',
    'Programming',
    'Research',
  ];

  // Goal options — icon is now an IconData
  static const List<Map<String, dynamic>> goals = [
    {
      'name': 'Find My Career',
      'icon': Icons.gps_fixed_rounded,
      'desc': 'Discover your path',
    },
    {
      'name': 'Improve Grades',
      'icon': Icons.trending_up_rounded,
      'desc': 'Excel academically',
    },
    {
      'name': 'Learn New Skills',
      'icon': Icons.psychology_rounded,
      'desc': 'Expand your toolkit',
    },
    {
      'name': 'Prepare for University',
      'icon': Icons.account_balance_rounded,
      'desc': 'Get university ready',
    },
  ];

  // Career results
  static const List<Map<String, dynamic>> careerResults = [
    {
      'title': 'Software Engineer',
      'match': 92,
      'description':
          'Design and build software systems, applications, and digital solutions.',
      'color': 0xFF052659,
      'icon': Icons.code_rounded,
    },
    {
      'title': 'Data Scientist',
      'match': 85,
      'description':
          'Analyze complex data to help organizations make informed decisions.',
      'color': 0xFF5483B3,
      'icon': Icons.analytics_rounded,
    },
    {
      'title': 'UI/UX Designer',
      'match': 80,
      'description':
          'Create beautiful, intuitive interfaces and seamless user experiences.',
      'color': 0xFF7DA0CA,
      'icon': Icons.design_services_rounded,
    },
    {
      'title': 'Product Manager',
      'match': 75,
      'description':
          'Lead product development from concept to launch and beyond.',
      'color': 0xFF1A6B4A,
      'icon': Icons.inventory_2_rounded,
    },
  ];

  // Image URLs for screens (Unsplash – free to use)
  static const String splashIllustration =
      'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=600&q=80';
  static const String loginIllustration =
      'https://images.unsplash.com/photo-1513530534585-c7b1394c6d51?w=600&q=80';
  static const String aiStudyBanner =
      'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=600&q=80';
}
