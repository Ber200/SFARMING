import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/soil_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';

class SoilManagementScreen extends StatefulWidget {
  const SoilManagementScreen({super.key});

  @override
  State<SoilManagementScreen> createState() => _SoilManagementScreenState();
}

class _SoilManagementScreenState extends State<SoilManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedFarmerId;
  final TextEditingController _moistureController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _moistureController.dispose();
    _phController.dispose();
    _statusController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Moisture Management'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firebaseService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final farmers =
              snapshot.data?.where((user) => user.isFarmer).toList() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Select Farmer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.farmCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Farmer',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFarmerId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        items: farmers.map((farmer) {
                          return DropdownMenuItem(
                            value: farmer.id,
                            child: Text('${farmer.name} (${farmer.email})'),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedFarmerId = value;
                            _errorMessage = null;
                          });
                          if (value != null) {
                            await _loadSoilData(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Soil Data Form
                if (_selectedFarmerId != null) ...[
                  StreamBuilder(
                    stream:
                        _firebaseService.getSoilDataStream(_selectedFarmerId!),
                    builder: (context, soilSnapshot) {
                      if (soilSnapshot.hasData && soilSnapshot.data != null) {
                        final soilData = soilSnapshot.data!;
                        if (_moistureController.text.isEmpty) {
                          _moistureController.text =
                              soilData.moisture?.toString() ?? '';
                          _phController.text = soilData.ph?.toString() ?? '';
                          _statusController.text = soilData.status ?? '';
                          _descriptionController.text =
                              soilData.description ?? '';
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.farmCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Soil Data',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            // Moisture Input
                            TextFormField(
                              controller: _moistureController,
                              decoration: InputDecoration(
                                labelText: 'Moisture (%)',
                                hintText: 'Enter moisture percentage (0-100)',
                                prefixIcon: const Icon(Icons.opacity),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            // pH Input
                            TextFormField(
                              controller: _phController,
                              decoration: InputDecoration(
                                labelText: 'pH Level',
                                hintText: 'Enter pH level (0-14)',
                                prefixIcon: const Icon(Icons.science),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            // Status Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _statusController.text.isEmpty
                                  ? null
                                  : _statusController.text,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                prefixIcon: const Icon(Icons.info),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'OK', child: Text('OK')),
                                DropdownMenuItem(
                                    value: 'LOW', child: Text('LOW')),
                                DropdownMenuItem(
                                    value: 'HIGH', child: Text('HIGH')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _statusController.text = value ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Enter detailed explanation',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            // Save Button
                            ElevatedButton(
                              onPressed: () => _saveSoilData(),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Save Soil Data'),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: AppTheme.farmCardDecoration(),
                    child: Column(
                      children: [
                        const Icon(Icons.agriculture,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Select a farmer to manage soil data',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadSoilData(String userId) async {
    try {
      final soilData = await _firebaseService.getSoilDataForUser(userId);
      if (soilData != null && mounted) {
        setState(() {
          _moistureController.text = soilData.moisture?.toString() ?? '';
          _phController.text = soilData.ph?.toString() ?? '';
          _statusController.text = soilData.status ?? '';
          _descriptionController.text = soilData.description ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load soil data: $e';
        });
      }
    }
  }

  Future<void> _saveSoilData() async {
    if (_selectedFarmerId == null) {
      setState(() {
        _errorMessage = 'Please select a farmer';
      });
      return;
    }

    try {
      setState(() {
        _errorMessage = null;
      });

      final moisture = _moistureController.text.isNotEmpty
          ? double.tryParse(_moistureController.text)
          : null;
      final ph = _phController.text.isNotEmpty
          ? double.tryParse(_phController.text)
          : null;

      if (moisture != null && (moisture < 0 || moisture > 100)) {
        setState(() {
          _errorMessage = 'Moisture must be between 0 and 100';
        });
        return;
      }

      if (ph != null && (ph < 0 || ph > 14)) {
        setState(() {
          _errorMessage = 'pH must be between 0 and 14';
        });
        return;
      }

      final soilProvider = Provider.of<SoilProvider>(context, listen: false);
      final success = await soilProvider.updateSoilDataForUser(
        userId: _selectedFarmerId!,
        ph: ph,
        moisture: moisture,
        status: _statusController.text.isEmpty ? null : _statusController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Soil data updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  soilProvider.errorMessage ?? 'Failed to update soil data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    }
  }
}
