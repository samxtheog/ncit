import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class PdfDoc {
  final String id;
  final String originalName;
  final int    size;
  final int    pages;
  final bool   hasText;
  final String preview;
  final int    messageCount;
  final DateTime createdAt;

  const PdfDoc({
    required this.id,
    required this.originalName,
    required this.size,
    required this.pages,
    required this.hasText,
    required this.preview,
    required this.messageCount,
    required this.createdAt,
  });

  factory PdfDoc.fromJson(Map<String, dynamic> j) => PdfDoc(
    id:           j['id'] as String,
    originalName: j['originalName'] as String,
    size:         (j['size'] as num).toInt(),
    pages:        (j['pages'] as num).toInt(),
    hasText:      j['hasText'] as bool? ?? false,
    preview:      j['preview'] as String? ?? '',
    messageCount: (j['messageCount'] as num?)?.toInt() ?? 0,
    createdAt:    DateTime.parse(j['createdAt'] as String),
  );

  String get sizeLabel {
    if (size < 1024)           return '${size}B';
    if (size < 1024 * 1024)   return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}

class ChatMessage {
  final String role;    // 'user' | 'assistant'
  final String content;
  final DateTime at;

  const ChatMessage({required this.role, required this.content, required this.at});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    role:    j['role']    as String,
    content: j['content'] as String,
    at:      DateTime.parse(j['at'] as String),
  );

  // local optimistic message
  factory ChatMessage.local(String role, String content) =>
      ChatMessage(role: role, content: content, at: DateTime.now());
}

// ── Service ───────────────────────────────────────────────────────────────────

class PdfService {
  static const _timeout = Duration(seconds: 45);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken) ?? '';
    return {'Authorization': 'Bearer $token'};
  }

  // ── Upload PDF (bytes work on both mobile and web) ────────────────────────

  Future<({PdfDoc pdf, String text})> uploadPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    final headers = await _authHeaders();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.pdfUpload),
    )
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromBytes(
        'pdf',
        bytes,
        filename: filename,
      ));

    final streamed = await req.send().timeout(_timeout);
    final body     = await streamed.stream.bytesToString();

    // Guard against HTML error pages from reverse proxy (e.g. nginx 413)
    if (!body.trimLeft().startsWith('{')) {
      if (streamed.statusCode == 413) {
        throw Exception('File too large. Please upload a smaller PDF.');
      }
      throw Exception('Upload failed (server error ${streamed.statusCode}).');
    }

    final data     = jsonDecode(body) as Map<String, dynamic>;

    if (streamed.statusCode == 201 && data['success'] == true) {
      return (
        pdf:  PdfDoc.fromJson(data['pdf'] as Map<String, dynamic>),
        text: data['text'] as String? ?? '',
      );
    }
    throw Exception(data['message'] ?? 'Upload failed.');
  }

  // ── List PDFs ─────────────────────────────────────────────────────────────

  Future<List<PdfDoc>> listPdfs() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse(ApiConstants.pdfList), headers: headers)
        .timeout(_timeout);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return (data['pdfs'] as List)
          .map((p) => PdfDoc.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to list PDFs.');
  }

  // ── Get single PDF (with full text + messages) ────────────────────────────

  Future<({PdfDoc pdf, String text, List<ChatMessage> messages})>
      getPdf(String id) async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('${ApiConstants.pdfList}/$id'), headers: headers)
        .timeout(_timeout);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return (
        pdf:  PdfDoc.fromJson(data['pdf'] as Map<String, dynamic>),
        text: data['text'] as String? ?? '',
        messages: (data['messages'] as List? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
    }
    throw Exception(data['message'] ?? 'Failed to load PDF.');
  }

  // ── Delete PDF ────────────────────────────────────────────────────────────

  Future<void> deletePdf(String id) async {
    final headers = await _authHeaders();
    await http
        .delete(Uri.parse('${ApiConstants.pdfList}/$id'), headers: headers)
        .timeout(_timeout);
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  Future<String> chat(String pdfId, String message) async {
    final headers = {
      ...(await _authHeaders()),
      'Content-Type': 'application/json',
    };
    final res = await http
        .post(
          Uri.parse('${ApiConstants.pdfList}/$pdfId/chat'),
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
}
