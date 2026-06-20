import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class AiChatMessage {
  final String role;    // 'user' | 'assistant'
  final String content;
  final DateTime at;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.at,
  });
    
  factory AiChatMessage.local(String role, String content) =>
      AiChatMessage(role: role, content: content, at: DateTime.now());
}

class ChatService {
  static const _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken) ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> send(String message) async {
    final headers = await _authHeaders();
    final res = await http
        .post(
          Uri.parse(ApiConstants.aiChat),
          headers: headers,
          body: jsonEncode({'message': message}),
        )
        .timeout(_timeout);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['reply'] as String;
    }
    throw Exception(data['message'] ?? 'AI error.');
  }

  Future<void> clearSession() async {
    final headers = await _authHeaders();
    await http
        .delete(Uri.parse(ApiConstants.aiChatClear), headers: headers)
        .timeout(_timeout);
  }
}
