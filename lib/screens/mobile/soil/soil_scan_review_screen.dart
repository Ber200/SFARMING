import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/soil_provider.dart';
import '../../../services/firebase_service.dart';
import '../../../services/soil_scan/soil_scan_result.dart';
import '../../../services/soil_scan/soil_scan_validator.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/custom_button.dart';

/// Review + edit screen shown after a successful sensor scan.
///
/// Nothing is saved until the farmer explicitly confirms the values.
class SoilScanReviewScreen extends StatefulWidget {
  const SoilScanReviewScreen({
    super.key,
    required this.result,
    required this.imageBytes,
  });

  final SoilScanResult result;
  final Uint8List imageBytes;

  @override
  State<SoilScanReviewScreen> createState() => _SoilScanReviewScreenState();
}

class _SoilScanReviewScreenState extends State<SoilScanReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fertilityController;
  late final TextEditingController _moistureController;
  late final TextEditingController _phController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _sunlightController;
  late final TextEditingController _humidityController;
  late final TextEditingController _nitrogenController;
  late final TextEditingController _phosphorusController;
  late final TextEditingController _potassiumController;
  late final TextEditingController _ecController;

  late String _temperatureUnit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final result = widget.result;
    _fertilityController =
        TextEditingController(text: _textFor(result, SoilScanField.fertility));
    _moistureController =
        TextEditingController(text: _textFor(result, SoilScanField.moisture));
    _phController = TextEditingController(text: _textFor(result, SoilScanField.ph));
    _temperatureController =
        TextEditingController(text: _textFor(result, SoilScanField.temperature));
    _sunlightController =
        TextEditingController(text: _textFor(result, SoilScanField.sunlight));
    _humidityController =
        TextEditingController(text: _textFor(result, SoilScanField.humidity));
    _nitrogenController =
        TextEditingController(text: _textFor(result, SoilScanField.nitrogen));
    _phosphorusController =
        TextEditingController(text: _textFor(result, SoilScanField.phosphorus));
    _potassiumController =
        TextEditingController(text: _textFor(result, SoilScanField.potassium));
    _ecController = TextEditingController(
        text: _textFor(result, SoilScanField.electricalConductivity));

    final tempUnit = result.valueFor(SoilScanField.temperature)?.unit;
    _temperatureUnit = tempUnit == '°F' ? '°F' : '°C';
  }

  /// Section 11 Rule: If a value has low confidence or is unreadable, DO NOT
  /// automatically populate a potentially incorrect value.
  String _textFor(SoilScanResult result, SoilScanField field) {
    final value = result.valueFor(field);
    if (value == null ||
        value.value == null ||
        value.status != ScanDetectionStatus.detected) {
      return '';
    }
    return _formatNumber(value.value!);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  double? _doubleOrNull(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _fertilityController.dispose();
    _moistureController.dispose();
    _phController.dispose();
    _temperatureController.dispose();
    _sunlightController.dispose();
    _humidityController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _ecController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final soilProvider = Provider.of<SoilProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isEmpty) {
      AppFeedback.error(context, 'You must be signed in to save sensor data.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sensor Data'),
        content: const Text(
          'Please make sure all readings match your device.\n\nDo you want to save these readings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);

    String? scanImageUrl;
    try {
      scanImageUrl = await FirebaseService().uploadSoilScanImage(
        userId,
        widget.imageBytes,
      );
    } catch (_) {}

    final success = await soilProvider.updateSoilData(
      userId: userId,
      ph: _doubleOrNull(_phController.text),
      moisture: _doubleOrNull(_moistureController.text),
      humidity: _doubleOrNull(_humidityController.text),
      fertility: _doubleOrNull(_fertilityController.text) ??
          _doubleOrNull(_ecController.text),
      electricalConductivity: _doubleOrNull(_ecController.text) ??
          _doubleOrNull(_fertilityController.text),
      nitrogen: _doubleOrNull(_nitrogenController.text),
      phosphorus: _doubleOrNull(_phosphorusController.text),
      potassium: _doubleOrNull(_potassiumController.text),
      temperature: _doubleOrNull(_temperatureController.text),
      temperatureUnit: _temperatureUnit,
      sunlight: _doubleOrNull(_sunlightController.text),
      source: 'device_scan',
      verifiedByFarmer: true,
      scanImage: scanImageUrl,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      AppFeedback.success(
        context,
        'Sensor Data Saved. Your verified sensor readings have been recorded successfully.',
      );
      Navigator.of(context).popUntil(
        (route) => route.settings.name == AppRoutes.soilMonitoring,
      );
    } else {
      AppFeedback.error(
        context,
        soilProvider.errorMessage ?? 'Failed to save sensor data.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Verify Sensor Data'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.soilMonitoring),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Please check the detected values before saving.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildVerifiedBanner(),
              const SizedBox(height: 16),
              _sectionHeader('SOIL MEASUREMENTS', Icons.grass_rounded),
              const SizedBox(height: 10),
              _FieldCard(
                field: SoilScanField.fertility,
                value: widget.result.valueFor(SoilScanField.fertility) ??
                    widget.result
                        .valueFor(SoilScanField.electricalConductivity),
                controller: _fertilityController,
                icon: Icons.grass_rounded,
                unit: 'µS/cm',
                validator: validateFertility,
                warningFor: (v) => warningForFertility(v),
              ),
              const SizedBox(height: 12),
              _FieldCard(
                field: SoilScanField.moisture,
                value: widget.result.valueFor(SoilScanField.moisture),
                controller: _moistureController,
                icon: Icons.water_drop_rounded,
                unit: '%',
                validator: validateMoisture,
              ),
              const SizedBox(height: 12),
              _FieldCard(
                field: SoilScanField.ph,
                value: widget.result.valueFor(SoilScanField.ph),
                controller: _phController,
                icon: Icons.science_rounded,
                unit: '',
                validator: validatePh,
              ),
              const SizedBox(height: 12),
              _FieldCard(
                field: SoilScanField.temperature,
                value: widget.result.valueFor(SoilScanField.temperature),
                controller: _temperatureController,
                icon: Icons.thermostat_rounded,
                unit: _temperatureUnit,
                isBusy: _saving,
                temperatureUnit: _temperatureUnit,
                onTemperatureUnitChanged: (unit) =>
                    setState(() => _temperatureUnit = unit),
                validator: (text) =>
                    validateTemperature(text, _temperatureUnit),
                warningFor: (v) => warningForTemperature(v, _temperatureUnit),
              ),
              const SizedBox(height: 20),
              _sectionHeader('ENVIRONMENT MEASUREMENTS', Icons.eco_rounded),
              const SizedBox(height: 10),
              _FieldCard(
                field: SoilScanField.sunlight,
                value: widget.result.valueFor(SoilScanField.sunlight),
                controller: _sunlightController,
                icon: Icons.wb_sunny_rounded,
                unit: 'LUX',
                validator: validateSunlight,
              ),
              const SizedBox(height: 12),
              _FieldCard(
                field: SoilScanField.humidity,
                value: widget.result.valueFor(SoilScanField.humidity),
                controller: _humidityController,
                icon: Icons.opacity_rounded,
                unit: '%',
                validator: validateHumidity,
              ),

              const SizedBox(height: 20),
              _buildScanImagePreview(),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Sensor Data',
                onPressed: _saving ? null : _confirmAndSave,
                isLoading: _saving,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Retake Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.brandPrimary,
                  side: const BorderSide(color: AppTheme.brandPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedBanner() {
    final lowCount = widget.result.values
        .where((v) => v.hasValue && v.status == ScanDetectionStatus.lowConfidence)
        .length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.brandLightest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brandLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.brandPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lowCount > 0
                  ? '$lowCount reading(s) need your attention. Verify them '
                      'before saving — your corrections replace the scanned values.'
                  : 'Readings were detected from your sensor screen. Correct '
                      'any mistakes, then confirm to save.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.brandPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.brandPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildScanImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Captured sensor screen',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              widget.imageBytes,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.value,
    required this.controller,
    required this.icon,
    required this.unit,
    required this.validator,
    this.warningFor,
    this.isBusy = false,
    this.temperatureUnit,
    this.onTemperatureUnitChanged,
  });

  final SoilScanField field;
  final SoilScanValue? value;
  final TextEditingController controller;
  final IconData icon;
  final String unit;
  final String? Function(String?) validator;
  final String? Function(double?)? warningFor;
  final bool isBusy;
  final String? temperatureUnit;
  final ValueChanged<String>? onTemperatureUnitChanged;

  @override
  Widget build(BuildContext context) {
    final scanValue = value;
    final isLowConfidence =
        scanValue?.status == ScanDetectionStatus.lowConfidence;
    final warning = warningFor?.call(_parse(controller.text));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.brandPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              _StatusBadge(value: scanValue),
            ],
          ),
          if (isLowConfidence) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    'Low confidence — please verify this reading.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter value',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: validator,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (field == SoilScanField.temperature &&
                  onTemperatureUnitChanged != null) ...[
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '°C', label: Text('°C')),
                    ButtonSegment(value: '°F', label: Text('°F')),
                  ],
                  selected: {temperatureUnit ?? '°C'},
                  onSelectionChanged: isBusy
                      ? null
                      : (selection) =>
                          onTemperatureUnitChanged?.call(selection.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 6),
            Text(
              warning,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.value});

  final SoilScanValue? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || !value!.hasValue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '✕ Not detected',
          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (value!.status == ScanDetectionStatus.lowConfidence) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '⚠ Check',
          style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '✓ Detected',
        style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
      ),
    );
  }
}
