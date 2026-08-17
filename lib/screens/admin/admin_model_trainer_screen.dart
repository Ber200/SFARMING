import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/detection_model.dart';
import '../../models/trained_model_info.dart';
import '../../providers/detection_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/model_trainer_bridge.dart';
import '../../utils/download_helper.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/app_feedback.dart';

class AdminModelTrainerScreen extends StatefulWidget {
  const AdminModelTrainerScreen({super.key});

  @override
  State<AdminModelTrainerScreen> createState() => _AdminModelTrainerScreenState();
}

class _AdminModelTrainerScreenState extends State<AdminModelTrainerScreen> {
  static const int _minClasses = 2;
  static const int _maxClasses = 8;
  static const int _minSamplesPerClass = 3;

  int _classCount = 2;
  late List<String> _classNames;
  late List<List<Uint8List>> _samples;
  final Map<String, int> _seedTarget = {};
  final Set<String> _seedingIds = {};

  bool _engineReady = false;
  String? _engineError;
  bool _training = false;
  bool _trained = false;
  bool _exporting = false;
  bool _uploading = false;
  double _progress = 0;
  double _loss = 0;
  double _acc = 0;
  String? _trainingError;
  TrainedModelInfo? _activeModel;

  @override
  void initState() {
    super.initState();
    _classNames = List.generate(_classCount, (i) => 'Class ${i + 1}');
    _samples = List.generate(_classCount, (_) => <Uint8List>[]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEngine();
      _loadActiveModel();
      final dp = context.read<DetectionProvider>();
      if (dp.detections.isEmpty && !dp.isLoading) {
        dp.loadDetections('');
      }
    });
  }

  String _displayName(int index) {
    final name = _classNames[index].trim();
    return name.isEmpty ? 'Class ${index + 1}' : name;
  }

  Future<void> _initEngine() async {
    try {
      await initModelTrainer();
      if (mounted) setState(() => _engineReady = true);
    } catch (e) {
      if (mounted) setState(() => _engineError = '$e');
    }
  }

  Future<void> _loadActiveModel() async {
    final info = await FirebaseService().getActiveModelOnce();
    if (mounted) setState(() => _activeModel = info);
  }

  void _setClassCount(int n) {
    setState(() {
      _classCount = n.clamp(_minClasses, _maxClasses);
      if (_classNames.length < _classCount) {
        _classNames.addAll(List.generate(
          _classCount - _classNames.length,
          (i) => 'Class ${_classNames.length + i + 1}',
        ));
      }
      _classNames = _classNames.sublist(0, _classCount);
      if (_samples.length < _classCount) {
        _samples.addAll(List.generate(
          _classCount - _samples.length,
          (_) => <Uint8List>[],
        ));
      }
      _samples = _samples.sublist(0, _classCount);
    });
  }

  Future<void> _pickImages(int classIndex) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final bytes = result.files
          .where((f) => f.bytes != null)
          .map((f) => f.bytes!)
          .toList();
      if (bytes.isEmpty) return;
      setState(() => _samples[classIndex].addAll(bytes));
    } catch (e) {
      if (mounted) AppFeedback.error(context, 'Could not pick images: $e');
    }
  }

  void _removeSample(int classIndex, int sampleIndex) {
    setState(() => _samples[classIndex].removeAt(sampleIndex));
  }

  void _clearClassSamples(int classIndex) {
    setState(() => _samples[classIndex].clear());
  }

  Future<void> _addDetectionToClass(DetectionModel detection) async {
    final classIndex =
        (_seedTarget[detection.id] ?? 0).clamp(0, _classCount - 1);
    setState(() => _seedingIds.add(detection.id));
    try {
      final response = await http.get(Uri.parse(detection.imageUrl));
      if (response.statusCode == 200) {
        setState(() => _samples[classIndex].add(response.bodyBytes));
        if (mounted) {
          AppFeedback.success(
            context,
            'Scan added to ${_displayName(classIndex)}.',
          );
        }
      } else {
        if (mounted) AppFeedback.error(context, 'Could not fetch that scan image.');
      }
    } catch (e) {
      if (mounted) AppFeedback.error(context, 'Failed to add scan: $e');
    } finally {
      if (mounted) setState(() => _seedingIds.remove(detection.id));
    }
  }

  bool get _canTrain =>
      _engineReady &&
      !_training &&
      !_samples.any((s) => s.length < _minSamplesPerClass);

  Future<void> _train() async {
    final missing = <String>[];
    for (var i = 0; i < _classCount; i++) {
      if (_samples[i].length < _minSamplesPerClass) missing.add(_displayName(i));
    }
    if (missing.isNotEmpty) {
      AppFeedback.error(
        context,
        'Add at least $_minSamplesPerClass samples to: ${missing.join(', ')}',
      );
      return;
    }

    setState(() {
      _training = true;
      _trained = false;
      _progress = 0;
      _loss = 0;
      _acc = 0;
      _trainingError = null;
    });

    final samplesAsDataUrls = List.generate(
      _classCount,
      (c) => _samples[c]
          .map((b) => 'data:image/jpeg;base64,${base64Encode(b)}')
          .toList(),
    );

    var finished = false;
    final training = trainModel(
      classNames: List.generate(_classCount, _displayName),
      samples: samplesAsDataUrls,
    );
    training.then((_) => finished = true).catchError((_) => finished = true);

    while (!finished) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final status = await getTrainerStatus();
        if (!mounted) break;
        setState(() {
          final total = (status['totalEpochs'] as num?)?.toDouble() ?? 1;
          final epoch = (status['epoch'] as num?)?.toDouble() ?? 0;
          _progress = (epoch / total).clamp(0.0, 1.0);
          _loss = (status['loss'] as num?)?.toDouble() ?? 0;
          _acc = (status['acc'] as num?)?.toDouble() ?? 0;
        });
      } catch (_) {}
    }

    try {
      await training;
      if (mounted) {
        setState(() {
          _training = false;
          _trained = true;
          _progress = 1;
        });
        AppFeedback.success(context, 'Model trained successfully.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _training = false;
          _trainingError = '$e';
        });
        AppFeedback.error(context, 'Training failed: $e');
      }
    }
  }

  Future<void> _exportModel() async {
    if (!_trained) return;
    setState(() => _exporting = true);
    try {
      await exportHeadModel();
      final labels = List.generate(_classCount, _displayName).join('\n');
      saveTextWeb('$labels\n', 'labels.txt');
      if (mounted) {
        AppFeedback.success(
          context,
          'TF.js model downloaded. Run tools/convert_to_tflite.py to produce model.tflite.',
        );
      }
    } catch (e) {
      if (mounted) AppFeedback.error(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deployModel() async {
    try {
      final tfliteResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tflite'],
        withData: true,
      );
      if (tfliteResult == null ||
          tfliteResult.files.isEmpty ||
          tfliteResult.files.single.bytes == null) {
        if (mounted) AppFeedback.error(context, 'Select a .tflite model file.');
        return;
      }

      final labelsResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );
      if (labelsResult == null ||
          labelsResult.files.isEmpty ||
          labelsResult.files.single.bytes == null) {
        if (mounted) AppFeedback.error(context, 'Select a labels.txt file.');
        return;
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Deploy new model'),
          content: const Text(
            'This activates the selected model for all farmers. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deploy'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _uploading = true);
      final info = await FirebaseService().uploadTrainedModel(
        tfliteBytes: tfliteResult.files.single.bytes!,
        labelsBytes: labelsResult.files.single.bytes!,
        classNames: List.generate(_classCount, _displayName),
      );
      if (mounted) {
        setState(() => _activeModel = info);
        AppFeedback.success(
          context,
          'Model deployed. Farmers pick it up on next app start.',
        );
      }
    } catch (e) {
      if (mounted) AppFeedback.error(context, 'Deploy failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'AI Model Trainer Studio',
      subtitle: 'Transfer learning, training sample curation & model deployment pipeline',
      activeRoute: AppRoutes.adminModelTrainer,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConfigureCard(),
                const SizedBox(height: 18),
                _buildSamplesCard(),
                const SizedBox(height: 18),
                _buildSeedCard(),
                const SizedBox(height: 18),
                _buildTrainCard(),
                const SizedBox(height: 18),
                _buildExportCard(),
                const SizedBox(height: 18),
                _buildDeployCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.adminPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.adminPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.adminTextPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildConfigureCard() {
    return _sectionCard(
      '1 · Disease Classification Classes',
      Icons.category_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Number of target classes:', style: TextStyle(fontSize: 13, color: AppTheme.adminTextSecondary)),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Fewer classes',
                onPressed: _classCount > _minClasses ? () => _setClassCount(_classCount - 1) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                alignment: Alignment.center,
                child: Text(
                  '$_classCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.adminPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'More classes',
                onPressed: _classCount < _maxClasses ? () => _setClassCount(_classCount + 1) : null,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < _classCount; i++)
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    key: ValueKey('class_name_$i'),
                    initialValue: _classNames[i],
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      labelText: 'Class ${i + 1} Name',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.label_outline_rounded, size: 16),
                      filled: true,
                      fillColor: AppTheme.adminSurfaceSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.adminBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.adminBorder)),
                      isDense: true,
                    ),
                    onChanged: (v) => _classNames[i] = v,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSamplesCard() {
    return _sectionCard(
      '2 · Training Sample Images',
      Icons.photo_library_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _classCount; i++) ...[
            _buildClassSampleTile(i),
            if (i < _classCount - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildClassSampleTile(int index) {
    final samples = _samples[index];
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  _displayName(index),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.adminTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.adminPrimaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${samples.length} samples',
                  style: const TextStyle(
                    color: AppTheme.adminPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImages(index),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                label: const Text('Upload Images', style: TextStyle(fontSize: 11.5)),
              ),
              if (samples.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _clearClassSamples(index),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ],
          ),
          if (samples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var s = 0; s < samples.length; s++)
                  _buildSampleThumb(index, s),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSampleThumb(int classIndex, int sampleIndex) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _samples[classIndex][sampleIndex],
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => _removeSample(classIndex, sampleIndex),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeedCard() {
    return _sectionCard(
      '3 · Field Scans for Supervised Labeling',
      Icons.manage_search_rounded,
      Consumer<DetectionProvider>(
        builder: (context, dp, _) {
          if (dp.isLoading && dp.detections.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.adminPrimary),
              ),
            );
          }

          final unknown = dp.detections.where(_isUnknownDetection).toList();
          if (unknown.isEmpty) {
            return const Text(
              'No unclassified or low-confidence scans pending review.',
              style: TextStyle(color: AppTheme.adminTextMuted, fontSize: 12.5),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign farmer scans with low confidence to appropriate disease classes to expand dataset.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
              ),
              const SizedBox(height: 12),
              for (final d in unknown) _buildSeedTile(d),
            ],
          );
        },
      ),
    );
  }

  bool _isUnknownDetection(DetectionModel d) {
    final label = d.disease.toLowerCase();
    return d.isLowConfidence ||
        label.contains('invalid') ||
        label.contains('unknown') ||
        label.contains('unrecognized');
  }

  String _seedLabel(DetectionModel d) {
    if (!_isUnknownDetection(d)) return d.disease;
    if (d.isLowConfidence) return 'Low-confidence scan';
    return 'Unrecognized scan';
  }

  Widget _buildSeedTile(DetectionModel d) {
    final target = (_seedTarget[d.id] ?? 0).clamp(0, _classCount - 1);
    final adding = _seedingIds.contains(d.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.adminSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.adminBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              d.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: AppTheme.adminBorderLight,
                child: const Icon(Icons.broken_image_rounded, color: AppTheme.adminTextMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _seedLabel(d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.adminTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMM d, y h:mm a').format(d.timestamp)} • ${(d.confidence * 100).toStringAsFixed(0)}% confidence',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: target,
            isDense: true,
            style: const TextStyle(fontSize: 12, color: AppTheme.adminTextPrimary),
            items: [
              for (var i = 0; i < _classCount; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(_displayName(i), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _seedTarget[d.id] = v);
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: adding ? null : () => _addDetectionToClass(d),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: AppTheme.adminPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: adding
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add Sample', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainCard() {
    return _sectionCard(
      '4 · Execute In-Browser Training',
      Icons.model_training_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_training) ...[
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: AppTheme.adminPrimaryLight,
              color: AppTheme.adminPrimary,
            ),
            const SizedBox(height: 10),
            Text(
              'Training… epoch ${(_progress * 50).round()}/50 · loss ${_loss.toStringAsFixed(3)} · accuracy ${(_acc * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
            ),
          ] else ...[
            if (_engineError != null) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Engine error: $_engineError', style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else if (!_engineReady) ...[
              const Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.adminPrimary)),
                  SizedBox(width: 10),
                  Text('Initializing WebGL training engine…', style: TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_trained) ...[
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Text('Model trained successfully — ready to export and deploy.', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_trainingError != null) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$_trainingError', style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _canTrain ? _train : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.adminPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.smart_toy_rounded, size: 18),
              label: const Text('Start Training Cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    return _sectionCard(
      '5 · Export Model Artifacts',
      Icons.download_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _trained && !_exporting ? _exportModel : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _exporting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download TF.js Model + Labels.txt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Convert downloaded weights using `tools/convert_to_tflite.py`, then deploy the compiled bundle below.',
            style: TextStyle(fontSize: 12, color: AppTheme.adminTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployCard() {
    final active = _activeModel;
    return _sectionCard(
      '6 · Deploy to Production App',
      Icons.cloud_upload_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active == null)
            const Text('No custom model version currently active in production.', style: TextStyle(color: AppTheme.adminTextMuted, fontSize: 12.5))
          else ...[
            _infoRow('Active Version', active.version),
            _infoRow(
              'Deployment Date',
              DateFormat('MMM d, y • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(active.timestamp)),
            ),
            _infoRow('Classes', active.classes.join(', ')),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _deployModel,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: _uploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Deploy .tflite + labels.txt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary)),
          ),
        ],
      ),
    );
  }
}

