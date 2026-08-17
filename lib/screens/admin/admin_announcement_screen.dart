import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/notification_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/app_feedback.dart';

/// Admin: compose and broadcast an announcement to every farmer.
class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final NotificationRepository _repository = NotificationRepository();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final relatedId = '${DateTime.now().millisecondsSinceEpoch}';

    try {
      final sent = await _repository.broadcastToFarmers(
        type: NotificationType.adminAnnouncement,
        title: title,
        body: body,
        relatedId: relatedId,
      );

      if (!mounted) return;
      if (sent == 0) {
        AppFeedback.error(context, 'No farmers found to notify.');
      } else {
        AppFeedback.success(context, 'Announcement successfully dispatched to $sent farmer(s).');
      }
      if (sent > 0) {
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, 'Failed to send announcement.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _titleController.text.trim();
    final bodyText = _bodyController.text.trim();

    return AdminScaffold(
      title: 'Farmer Broadcast Center',
      subtitle: 'Dispatch urgent advisories, agronomic alerts & weather bulletins to all registered field users',
      activeRoute: AppRoutes.adminAnnouncement,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Container
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.adminCardDecoration(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.adminPrimaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.campaign_rounded, color: AppTheme.adminPrimary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compose Broadcast',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.adminTextPrimary),
                                  ),
                                  Text(
                                    'Dispatches instant push alerts into farmer notification feeds',
                                    style: TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Subject Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.adminTextPrimary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleController,
                            maxLength: 80,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. Severe Weather Advisory: Heavy Rain Warning',
                              hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextMuted),
                              prefixIcon: const Icon(Icons.title_rounded, size: 18),
                              filled: true,
                              fillColor: AppTheme.adminSurfaceSubtle,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.adminBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.adminBorder)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 14),
                          const Text('Announcement Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.adminTextPrimary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _bodyController,
                            maxLines: 6,
                            maxLength: 500,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Provide detailed instructions or precautionary recommendations for field farmers...',
                              hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextMuted),
                              filled: true,
                              fillColor: AppTheme.adminSurfaceSubtle,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.adminBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.adminBorder)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _isSending ? null : _sendAnnouncement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.adminPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                _isSending ? 'Transmitting Broadcast...' : 'Broadcast to All Farmers',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Live Mobile Preview Card
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppTheme.adminCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_iphone_rounded, size: 18, color: AppTheme.adminPrimary),
                            SizedBox(width: 8),
                            Text('Farmer App Feed Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.adminSurfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.adminBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.adminPrimaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.campaign_rounded, size: 14, color: AppTheme.adminPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'SMARTFARMING Admin Alert',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.adminPrimary),
                                    ),
                                  ),
                                  const Text('Just now', style: TextStyle(fontSize: 10, color: AppTheme.adminTextMuted)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                titleText.isNotEmpty ? titleText : 'Advisory Headline will appear here',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: titleText.isNotEmpty ? AppTheme.adminTextPrimary : AppTheme.adminTextMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bodyText.isNotEmpty ? bodyText : 'Detailed alert body content and recommendations will be formatted here for mobile viewing.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: bodyText.isNotEmpty ? AppTheme.adminTextSecondary : AppTheme.adminTextMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

