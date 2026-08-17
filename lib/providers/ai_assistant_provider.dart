import 'package:flutter/foundation.dart';

import '../models/ai_message_model.dart';
import '../services/ai_assistant_service.dart';
import '../services/ai_context_builder.dart';
import '../services/local_storage_service.dart';

/// Manages the AI assistant conversation for the current farmer.
///
/// Holds the message list in memory, persists it to a per-user Hive box, and
/// grounds every request in the farmer's detections/treatments/soil/weather.
class AiAssistantProvider with ChangeNotifier {
  final AiAssistantService _service = const AiAssistantService();

  List<AiMessage> _messages = [];
  bool _isSending = false;
  String? _userId;
  String? _diseaseContext;

  static const int _maxHistoryMessages = 20;

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  /// Disease context set when the assistant is opened from a detection result.
  String? get diseaseContext => _diseaseContext;

  /// Links this provider to a farmer and restores their stored conversation.
  void bindUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _diseaseContext = null;
    _loadHistory();
  }

  void setDiseaseContext(String? disease) {
    _diseaseContext = disease;
  }

  void addMessage(AiMessage message) {
    _messages = [..._messages, message];
    if (_messages.length > _maxHistoryMessages) {
      _messages = _messages.sublist(_messages.length - _maxHistoryMessages);
    }
    _saveHistory();
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    final stored = LocalStorageService.getChatMessages(userId);
    if (stored.isEmpty) return;
    _messages = stored;
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    await LocalStorageService.saveChatMessages(userId, _messages);
  }

  /// Sends the farmer's question to Gemini and appends the reply.
  ///
  /// Returns true when the assistant produced a reply. When offline or on
  /// failure, an error bubble (holding a localization key) is appended.
  Future<bool> sendMessage({
    required String text,
    required bool isOnline,
    required String languageCode,
    String? farmSnapshot,
  }) async {
    final question = text.trim();
    if (question.isEmpty || _isSending) return false;

    if (!isOnline) {
      _appendError('ai_offline');
      return false;
    }

    addMessage(AiMessage(role: 'user', text: question, timestamp: DateTime.now()));
    _isSending = true;
    notifyListeners();

    try {
      final systemPrompt = AiContextBuilder.systemPrompt(
        languageCode: languageCode,
        diseaseContext: _diseaseContext,
      );
      final prompt = (farmSnapshot != null && farmSnapshot.isNotEmpty)
          ? '$systemPrompt\n\n$farmSnapshot'
          : systemPrompt;
      final reply = await _service.ask(
        question: question,
        systemPrompt: prompt,
        history: _historyText(),
      );
      addMessage(
        AiMessage(role: 'assistant', text: reply, timestamp: DateTime.now()),
      );
      return true;
    } on AiAssistantException catch (e) {
      _appendError(_friendlyErrorKey(e.code));
      return false;
    } catch (_) {
      _appendError('ai_error');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  String _historyText() {
    final recent = _messages.length <= _maxHistoryMessages
        ? _messages
        : _messages.sublist(_messages.length - _maxHistoryMessages);
    return recent
        .where((m) => !m.isError)
        .map((m) => '${m.isUser ? 'Farmer' : 'AgriGuide'}: ${m.text}')
        .join('\n');
  }

  String _friendlyErrorKey(String code) {
    switch (code) {
      case 'no_key':
        return 'ai_no_key';
      case 'timeout':
        return 'ai_timeout';
      case 'rate_limited':
        return 'ai_rate_limited';
      case 'server_error':
        return 'ai_server_error';
      default:
        return 'ai_error';
    }
  }

  void _appendError(String l10nKey) {
    addMessage(AiMessage(
      role: 'assistant',
      text: l10nKey,
      timestamp: DateTime.now(),
      isError: true,
    ));
  }

  Future<void> clearChat() async {
    _messages = [];
    _diseaseContext = null;
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      await LocalStorageService.clearChatMessages(userId);
    }
    notifyListeners();
  }
}
