import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ai_message_model.dart';
import '../../../providers/ai_assistant_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/soil_provider.dart';
import '../../../providers/treatment_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../services/ai_context_builder.dart';

/// Full-screen AI Farm Assistant.
///
/// Pushed as a normal route so it has its own [Scaffold] (valid Material
/// ancestor) and lives inside the Navigator - unlike the old floating bubble
/// that crashed outside the Overlay.
class AiAssistantScreen extends StatefulWidget {
  /// When opened from a detection result, the detected disease name.
  final String? disease;

  const AiAssistantScreen({super.key, this.disease});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final ai = context.read<AiAssistantProvider>();
      ai.bindUser(auth.currentUser?.id ?? '');
      ai.setDiseaseContext(widget.disease);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    final ai = context.read<AiAssistantProvider>();
    final connectivity = context.read<ConnectivityProvider>();
    final auth = context.read<AuthProvider>();
    final language = context.read<LanguageProvider>();

    await ai.sendMessage(
      text: text,
      isOnline: connectivity.isOnline && !auth.isOfflineMode,
      languageCode: language.language.code,
      farmSnapshot: _buildSnapshot(),
    );
    _scrollToBottom();
  }

  String _buildSnapshot() {
    return AiContextBuilder.farmSnapshot(
      detections: context.read<DetectionProvider>().detections,
      treatments: context.read<TreatmentProvider>().treatments,
      soil: context.read<SoilProvider>().soilData,
      weather: context.read<WeatherProvider>().currentWeather,
      farmLocation: context.read<AuthProvider>().currentUser?.farmLocation,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('ai_clear_confirm')),
        content: Text(l10n.translate('ai_clear_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('ai_clear_chat')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AiAssistantProvider>().clearChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: Text(l10n.translate('ai_chat_title')),
        actions: [
          IconButton(
            tooltip: l10n.translate('ai_clear_chat'),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.disease != null && widget.disease!.isNotEmpty)
            _buildDiseaseBanner(context, l10n),
          Expanded(child: _buildMessageList(context, l10n)),
          _buildTypingIndicator(context, l10n),
          _buildInputBar(context, l10n),
        ],
      ),
    );
  }

  Widget _buildDiseaseBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.brandPrimary.withValues(alpha: 0.10),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: AppTheme.brandPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.translate('ai_asking_about', {'disease': widget.disease!}),
              style: TextStyle(
                color: AppTheme.brandPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, AppLocalizations l10n) {
    return Consumer<AiAssistantProvider>(
      builder: (context, ai, _) {
        if (ai.messages.isEmpty) {
          return _buildEmptyState(context, l10n);
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: ai.messages.length,
          itemBuilder: (context, index) =>
              _buildMessage(context, ai.messages[index], l10n),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _buildMessage(
          context,
          AiMessage(
            role: 'assistant',
            text: l10n.translate('ai_welcome'),
            timestamp: DateTime.now(),
          ),
          l10n,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'ai_chip_ph',
              'ai_chip_moisture',
              'ai_chip_disease',
              'ai_chip_fertilizer',
            ].map((key) {
              return ActionChip(
                label: Text(l10n.translate(key)),
                labelStyle: const TextStyle(fontSize: 12.5),
                backgroundColor: const Color(0xFFE8F3EC),
                side: BorderSide(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.25),
                ),
                onPressed: () => _send(l10n.translate(key)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(
    BuildContext context,
    AiMessage message,
    AppLocalizations l10n,
  ) {
    final text = message.isError ? l10n.translate(message.text) : message.text;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.brandPrimary
              : (message.isError ? const Color(0xFFFDECEA) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SelectableText(
          text,
          style: TextStyle(
            color: message.isError
                ? Colors.red.shade800
                : (isUser ? Colors.white : Colors.black87),
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context, AppLocalizations l10n) {
    return Consumer<AiAssistantProvider>(
      builder: (context, ai, _) {
        if (!ai.isSending) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.translate('ai_typing'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: l10n.translate('ai_hint'),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<AiAssistantProvider>(
              builder: (context, ai, _) {
                final enabled = !ai.isSending;
                return Material(
                  color: enabled ? AppTheme.brandPrimary : Colors.grey.shade400,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: enabled ? () => _send(_controller.text) : null,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
