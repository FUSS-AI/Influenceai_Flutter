import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

// ── Typed error ────────────────────────────────────────────────────────────────

/// Custom error type for API failures.
class ApiError implements Exception {
  final String message;
  final int statusCode;

  ApiError(this.message, this.statusCode);

  @override
  String toString() => 'ApiError($statusCode): $message';
}

// ── API Service ────────────────────────────────────────────────────────────────

/// REST API client for the soulchat-ai gateway.
///
/// Mirrors the Vue `api.js` surface. Auth is handled via `X-API-Key` and
/// `X-External-User-ID` headers.
class ApiService {
  final String baseUrl;
  final String apiKey;

  ApiService({
    this.baseUrl = AppConfig.apiBaseUrl,
    this.apiKey = AppConfig.apiKey,
  });

  // ── Base request ──────────────────────────────────────────────────────────

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? userId,
  }) async {
    if (apiKey.isEmpty) {
      throw ApiError('API_KEY is not set. Check your configuration.', 0);
    }

    final uri = Uri.parse('$baseUrl$path');

    final resolvedUserId = userId ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (apiKey.startsWith('ey')) 'Authorization': 'Bearer $apiKey' else 'X-API-Key': apiKey,
      'X-External-User-ID': resolvedUserId,
    };

    late http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw ApiError('Unsupported HTTP method: $method', 0);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError('Network error: $e', 0);
    }

    if (response.statusCode == 204) return null;

    if (response.statusCode >= 400) {
      String detail = response.reasonPhrase ?? 'Unknown error';
      try {
        final json = jsonDecode(response.body);
        detail = (json['detail'] ?? json['message'] ?? detail).toString();
      } catch (_) {
        // Non-JSON error body — use reason phrase.
      }
      throw ApiError(detail, response.statusCode);
    }

    return jsonDecode(response.body);
  }

  // ── API surface ───────────────────────────────────────────────────────────

  /// Create a voice session via soulchat-ai.
  ///
  /// Calls `POST /session` which internally dispatches to InfluenceAI
  /// and returns a LiveKit token.
  ///
  /// Returns `{ session_id, livekit_url, token, room_name }`.
  Future<Map<String, dynamic>> createSession(
    String personaId, {
    String? userId,
    String? instructionsOverride,
    String? webhookUrl,
  }) async {
    final agentConfig = <String, dynamic>{
      'influencer_id': personaId,
    };
    if (instructionsOverride != null && instructionsOverride.isNotEmpty) {
      agentConfig['instructions_override'] = instructionsOverride;
    }

    final body = <String, dynamic>{
      'agent_config': agentConfig,
      if (webhookUrl != null) 'webhook_url': webhookUrl,
    };

    final isDirectRouter = baseUrl.contains('8000');
    final endpoint = isDirectRouter ? '/sessions' : '/session';
    final result = await _request('POST', endpoint, body: body, userId: userId);
    return Map<String, dynamic>.from(result as Map);
  }

  /// Sessions end automatically when the LiveKit room closes.
  /// Kept for API compatibility.
  Future<void> endSession(String sessionId) async {
    // No-op — mirrors Vue SDK behaviour.
  }

  /// Get list of available personas/characters.
  Future<List<dynamic>> getPersonas() async {
    final result = await _request('GET', '/list');
    return result is List ? result : [];
  }

  /// Get a user's conversation memory for a specific persona.
  ///
  /// Returns `{ context_text }` with long-term facts and past conversations.
  Future<Map<String, dynamic>> getMemory(
    String personaId, {
    String? userId,
  }) async {
    final qs = userId != null ? '?user_id=${Uri.encodeComponent(userId)}' : '';
    final result = await _request('GET', '/memory/$personaId$qs', userId: userId);
    return Map<String, dynamic>.from(result as Map);
  }

  // Recording is managed server-side.
  Future<void> startRecording(String sessionId) async {}
  Future<void> stopRecording(String sessionId) async {}

  // Transcripts are persisted automatically after each call.
  Future<void> saveTranscript(String sessionId, List<Map<String, dynamic>> messages) async {}
}
