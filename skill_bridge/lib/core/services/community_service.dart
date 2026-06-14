import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class CommunityComment {
  final String id;
  final String userId;
  final String name;
  final String content;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.userId,
    required this.name,
    required this.content,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> j) =>
      CommunityComment(
        id:        j['id'] as String,
        userId:    j['userId'] as String,
        name:      j['name'] as String,
        content:   j['content'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class CommunityPost {
  final String id;
  final String userId;
  final String name;
  final String content;
  final String tag;
  final int likeCount;
  final bool likedByMe;
  final int commentCount;
  final List<CommunityComment> comments;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.name,
    required this.content,
    required this.tag,
    required this.likeCount,
    required this.likedByMe,
    required this.commentCount,
    required this.comments,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id:           j['id'] as String,
        userId:       j['userId'] as String,
        name:         j['name'] as String,
        content:      j['content'] as String,
        tag:          j['tag'] as String? ?? 'General',
        likeCount:    (j['likeCount'] as num).toInt(),
        likedByMe:    j['likedByMe'] as bool? ?? false,
        commentCount: (j['commentCount'] as num).toInt(),
        comments: (j['comments'] as List? ?? [])
            .map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  CommunityPost copyWith({int? likeCount, bool? likedByMe,
      int? commentCount, List<CommunityComment>? comments}) =>
      CommunityPost(
        id:           id,
        userId:       userId,
        name:         name,
        content:      content,
        tag:          tag,
        likeCount:    likeCount    ?? this.likeCount,
        likedByMe:    likedByMe    ?? this.likedByMe,
        commentCount: commentCount ?? this.commentCount,
        comments:     comments     ?? this.comments,
        createdAt:    createdAt,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class CommunityService {
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken) ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Fetch posts (paginated) ───────────────────────────────────────────────

  Future<({List<CommunityPost> posts, int total, int pages})> getPosts({
    int page = 1,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('${ApiConstants.communityPosts}?page=$page&limit=15');
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      final posts = (data['posts'] as List)
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList();
      return (
        posts: posts,
        total: (data['total'] as num).toInt(),
        pages: (data['pages'] as num).toInt(),
      );
    }
    throw Exception(data['message'] ?? 'Failed to load posts.');
  }

  // ── Create post ───────────────────────────────────────────────────────────

  Future<CommunityPost> createPost({
    required String content,
    required String tag,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse(ApiConstants.communityPosts),
          headers: headers,
          body: jsonEncode({'content': content, 'tag': tag}),
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && data['success'] == true) {
      return CommunityPost.fromJson(data['post'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to create post.');
  }

  // ── Toggle like ───────────────────────────────────────────────────────────

  Future<({int likeCount, bool likedByMe})> toggleLike(String postId) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('${ApiConstants.communityPosts}/$postId/like'),
          headers: headers,
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return (
        likeCount: (data['likeCount'] as num).toInt(),
        likedByMe: data['likedByMe'] as bool,
      );
    }
    throw Exception(data['message'] ?? 'Failed to like post.');
  }

  // ── Add comment ───────────────────────────────────────────────────────────

  Future<CommunityComment> addComment(String postId, String content) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('${ApiConstants.communityPosts}/$postId/comments'),
          headers: headers,
          body: jsonEncode({'content': content}),
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && data['success'] == true) {
      return CommunityComment.fromJson(
          data['comment'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to post comment.');
  }

  // ── Delete post ───────────────────────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    final headers = await _authHeaders();
    final response = await http
        .delete(
          Uri.parse('${ApiConstants.communityPosts}/$postId'),
          headers: headers,
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete post.');
    }
  }
}
