import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// Handles all HTTP communication with the ActiveGlow FastAPI backend.
class ChatApiService {
  ChatApiService._();
  static final ChatApiService instance = ChatApiService._();

  final _client = http.Client();
  final _baseUrl = AppConstants.apiBaseUrl;

  // ── Send a chat message ────────────────────────────────────────────────────
  /// Posts a message to /chat and returns the bot's reply string.
  /// Throws [ChatApiException] on network or server errors.
  Future<String> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'session_id': sessionId,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String;
      } else {
        final errorBody = jsonDecode(response.body);
        throw ChatApiException(
          'Server error ${response.statusCode}: '
          '${errorBody['detail'] ?? 'Unknown error'}',
        );
      }
    } on ChatApiException {
      rethrow;
    } catch (e) {
      throw ChatApiException(
        'Unable to reach Skye right now. '
        'Please check your connection and try again.\n\nDetails: $e',
      );
    }
  }

  // ── Clear a session ────────────────────────────────────────────────────────
  Future<void> clearSession(String sessionId) async {
    final uri = Uri.parse('$_baseUrl/session/$sessionId');
    try {
      await _client
          .delete(uri)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort — ignore errors during session clear.
    }
  }

  // ── Health check ───────────────────────────────────────────────────────────
  Future<bool> isBackendReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Typed exception for API errors — gives the UI something meaningful to display.
class ChatApiException implements Exception {
  final String message;
  const ChatApiException(this.message);

  @override
  String toString() => message;
}
