import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/gemini_config.dart';

/// Thin REST client for the Gemini `generateContent` endpoint.
///
/// Uses the native endpoint and sends the key in the `x-goog-api-key` header,
/// which is compatible with both legacy `AIza...` and new `AQ...` keys.
class AiAssistantService {
  const AiAssistantService();

  /// Sends a single-turn question with a system instruction and optional
  /// conversation history. Returns the assistant's reply text.
  ///
  /// Set [responseMimeType] to `application/json` to request structured JSON
  /// output, and override [maxOutputTokens] when the reply must be longer than
  /// the configured default.
  Future<String> ask({
    required String question,
    required String systemPrompt,
    String? history,
    String? responseMimeType,
    int? maxOutputTokens,
  }) async {
    if (!GeminiConfig.hasApiKey) {
      // Safe diagnostic — no key content is logged.
      debugPrint('[AiAssistantService] GEMINI_API_KEY not compiled in. '
          'Rebuild with --dart-define=GEMINI_API_KEY=YOUR_KEY');
      throw AiAssistantException('no_key');
    }

    final contents = <Map<String, dynamic>>[
      if (history != null && history.isNotEmpty)
        {
          'role': 'user',
          'parts': [
            {'text': 'Previous conversation:\n$history'},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    final generationConfig = <String, dynamic>{
      'temperature': GeminiConfig.temperature,
      'maxOutputTokens': maxOutputTokens ?? GeminiConfig.maxOutputTokens,
      if (responseMimeType != null) 'responseMimeType': responseMimeType,
    };

    final body = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'generationConfig': generationConfig,
    };

    final uri = GeminiConfig.generateContentUri();
    debugPrint('[AiAssistantService] Sending request → ${uri.host}${uri.path}');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': GeminiConfig.apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(GeminiConfig.timeout);
    } on TimeoutException {
      debugPrint(
          '[AiAssistantService] Request timed out after ${GeminiConfig.timeout.inSeconds}s');
      throw AiAssistantException('timeout');
    } catch (e) {
      // On Flutter Web, CORS/network failures surface as generic exceptions.
      // generativelanguage.googleapis.com supports browser CORS, so this
      // typically indicates a network connectivity issue.
      debugPrint('[AiAssistantService] Network error: ${e.runtimeType}');
      throw AiAssistantException('network');
    }

    debugPrint('[AiAssistantService] Gemini HTTP status: ${response.statusCode}');

    if (response.statusCode == 400) {
      debugPrint('[AiAssistantService] Bad request (400) — check request body format.');
      throw AiAssistantException('api_error',
          statusCode: 400, body: response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('[AiAssistantService] Auth error (${response.statusCode}) — '
          'API key may be invalid, expired, or restricted.');
      throw AiAssistantException('api_error',
          statusCode: response.statusCode, body: response.body);
    }
    if (response.statusCode == 429) {
      debugPrint('[AiAssistantService] Rate limited (429) — quota exceeded.');
      throw AiAssistantException('rate_limited');
    }
    if (response.statusCode >= 500) {
      debugPrint(
          '[AiAssistantService] Gemini server error (${response.statusCode}).');
      throw AiAssistantException('server_error');
    }
    if (response.statusCode != 200) {
      debugPrint(
          '[AiAssistantService] Unexpected status: ${response.statusCode}');
      throw AiAssistantException('api_error',
          statusCode: response.statusCode, body: response.body);
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List? ?? [];
      final text = _extractText(candidates);
      if (text == null || text.trim().isEmpty) {
        debugPrint('[AiAssistantService] Empty response — '
            'possible safety filter or empty candidates list.');
        throw AiAssistantException('empty_response');
      }
      debugPrint('[AiAssistantService] Response received successfully.');
      return text.trim();
    } catch (e) {
      if (e is AiAssistantException) rethrow;
      throw AiAssistantException('parse_error',
          statusCode: response.statusCode, body: response.body);
    }
  }

  String? _extractText(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final content = (candidate as Map<String, dynamic>)['content'];
      if (content is Map<String, dynamic>) {
        final parts = content['parts'] as List? ?? [];
        for (final part in parts) {
          final text = (part as Map<String, dynamic>)['text'];
          if (text is String && text.isNotEmpty) return text;
        }
      }
    }
    return null;
  }
}

/// Typed error surfaced by [AiAssistantService]. [code] is a stable machine
/// key that providers map to localized messages.
///
/// Codes:
/// - `no_key`       — GEMINI_API_KEY not compiled into the binary.
/// - `timeout`      — request exceeded [GeminiConfig.timeout].
/// - `network`      — network/CORS error before a response was received.
/// - `rate_limited` — HTTP 429, quota exceeded.
/// - `server_error` — HTTP 5xx from Gemini.
/// - `api_error`    — any other non-200 response (check [statusCode]).
/// - `empty_response` — model returned no text (safety filter etc.).
/// - `parse_error`  — response body could not be decoded.
class AiAssistantException implements Exception {
  final String code;
  final int? statusCode;
  final String? body;

  AiAssistantException(this.code, {this.statusCode, this.body});

  @override
  String toString() => 'AiAssistantException($code, statusCode: $statusCode)';
}
