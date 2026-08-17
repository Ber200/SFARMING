import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/treatment_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/disease_info_model.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class AddTreatmentScreen extends StatefulWidget {
  final String? preFilledDisease;

  const AddTreatmentScreen({super.key, this.preFilledDisease});

  @override
  State<AddTreatmentScreen> createState() => _AddTreatmentScreenState();
}

class _AddTreatmentScreenState extends State<AddTreatmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'treatment';
  String? _selectedDisease;
  String? _remedy;
  bool _isSubmitting = false;

  final _diseases = DiseaseInfoModel.getAllDiseasesForTreatment();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate.isBefore(today)) {
      _selectedDate = today;
    }
    if (widget.preFilledDisease != null &&
        widget.preFilledDisease!.trim().isNotEmpty) {
      _selectedDisease = widget.preFilledDisease!;
      _remedy = DiseaseInfoModel.getDiseaseInfo(_selectedDisease!)?.treatmentProtocol;
    } else if (_diseases.isNotEmpty) {
      _selectedDisease = _diseases.first.name;
      _remedy = _diseases.first.treatmentProtocol;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTreatment() async {
    if (_isSubmitting) return;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedType == 'treatment' &&
        (_selectedDisease == null || _selectedDisease!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectDisease),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final treatmentProvider =
        Provider.of<TreatmentProvider>(context, listen: false);
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);

    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSignIn),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final scheduleDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (weatherProvider.currentWeather?.isRainy ?? false) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.rainWarning),
            content: Text(l10n.rainWarningContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.continueText),
              ),
            ],
          );
        },
      );
      if (shouldContinue != true) return;
    }

    final diseaseValue = _selectedType == 'fertilization'
        ? 'Fertilization'
        : _selectedDisease!;
    setState(() => _isSubmitting = true);
    final success = await treatmentProvider.addTreatment(
      userId: userId,
      disease: diseaseValue,
      remedy: _remedy,
      scheduleDate: scheduleDate,
      type: _selectedType,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.treatmentSubmittedPending),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            treatmentProvider.errorMessage ??
                AppLocalizations.of(context)!.failedToSchedule,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            }
          },
          tooltip: 'Back',
        ),
        title: Text(AppLocalizations.of(context)!.scheduleTreatment),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'treatment',
                        child: Text(AppLocalizations.of(context)!.treatment)),
                    DropdownMenuItem(
                        value: 'fertilization',
                        child: Text(AppLocalizations.of(context)!.fertilization)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        if (value == 'fertilization') {
                          _selectedDisease = 'Fertilization';
                          _remedy = null;
                        } else if (_selectedDisease == 'Fertilization' || _diseases.any((d) => d.name == _selectedDisease)) {
                          _selectedDisease = _diseases.isNotEmpty ? _diseases.first.name : null;
                          _remedy = _diseases.isNotEmpty ? _diseases.first.treatmentProtocol : null;
                        }
                      });
                    }
                  },
                ),
                if (_selectedType == 'treatment') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDisease,
                    decoration: const InputDecoration(
                      labelText: 'Disease Name',
                      prefixIcon: Icon(Icons.bug_report),
                    ),
                    items: _diseases
                        .map((d) => DropdownMenuItem(
                              value: d.name,
                              child: Text(d.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDisease = value;
                        _remedy = DiseaseInfoModel.getDiseaseInfo(value ?? '')?.treatmentProtocol;
                      });
                    },
                  ),
                ],
                if (_selectedType == 'treatment' && _remedy != null && _remedy!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.medical_services,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Recommended Remedy / Medicine',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_remedy!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child:
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _notesController,
                  label: AppLocalizations.of(context)!.notesOptional,
                  hint: AppLocalizations.of(context)!.addNotesHint,
                  prefixIcon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Consumer<TreatmentProvider>(
                  builder: (context, treatmentProvider, _) {
                    return CustomButton(
                      text: 'Submit ${_selectedType == 'treatment' ? 'Treatment' : 'Fertilization'}',
                      onPressed:
                          (treatmentProvider.isLoading || _isSubmitting) ? null : _saveTreatment,
                      isLoading: treatmentProvider.isLoading || _isSubmitting,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
