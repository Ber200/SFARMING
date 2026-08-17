import 'dart:async';
import 'dart:convert';

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
      throw AiAssistantException('timeout');
    } catch (_) {
      throw AiAssistantException('network');
    }

    if (response.statusCode == 429) {
      throw AiAssistantException('rate_limited');
    }
    if (response.statusCode >= 500) {
      throw AiAssistantException('server_error');
    }
    if (response.statusCode != 200) {
      throw AiAssistantException(
        'api_error',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List? ?? [];
      final text = _extractText(candidates);
      if (text == null || text.trim().isEmpty) {
        throw AiAssistantException('empty_response');
      }
      return text.trim();
    } catch (e) {
      throw AiAssistantException(
        'parse_error',
        statusCode: response.statusCode,
        body: response.body,
      );
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
/// key the provider maps to a localized message.
class AiAssistantException implements Exception {
  final String code;
  final int? statusCode;
  final String? body;

  AiAssistantException(this.code, {this.statusCode, this.body});

  @override
  String toString() => 'AiAssistantException($code)';
}
