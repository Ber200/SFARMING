/// Validation for soil sensor readings.
///
/// Rules follow the scanner spec: reject truly invalid input, but only warn
/// (never block or silently change) readings that are unusual.
library;

String? _numericError(String? text, {String? label}) {
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim()) == null) {
    return '${label ?? 'Value'} must be a valid number.';
  }
  return null;
}

String? _rangeError(String? text, double min, double max, {String? label}) {
  final numeric = _numericError(text, label: label);
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  final value = double.tryParse(text.trim());
  if (value == null) return null;
  if (value < min || value > max) {
    return '${label ?? 'Value'} must be between $min and $max.';
  }
  return null;
}

String? validateFertility(String? text) {
  final numeric = _numericError(text, label: 'Fertility');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim())! < 0) {
    return 'Fertility must not be negative.';
  }
  return null;
}

String? validateMoisture(String? text) =>
    _rangeError(text, 0, 100, label: 'Moisture');

String? validateHumidity(String? text) =>
    _rangeError(text, 0, 100, label: 'Humidity');

String? validatePh(String? text) => _rangeError(text, 0, 14, label: 'pH');

String? validateTemperature(String? text, String unit) {
  final numeric = _numericError(text, label: 'Temperature');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  final value = double.tryParse(text.trim())!;
  if (unit == '°F' && (value < 32 || value > 140)) {
    return 'Temperature must be between 32°F and 140°F.';
  }
  if (unit != '°F' && (value < -20 || value > 60)) {
    return 'Temperature must be between -20°C and 60°C.';
  }
  return null;
}

String? validateSunlight(String? text) {
  final numeric = _numericError(text, label: 'Sunlight');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim())! < 0) {
    return 'Sunlight must not be negative.';
  }
  return null;
}

String? validateNitrogen(String? text) {
  final numeric = _numericError(text, label: 'Nitrogen');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim())! < 0) {
    return 'Nitrogen must not be negative.';
  }
  return null;
}

String? validatePhosphorus(String? text) {
  final numeric = _numericError(text, label: 'Phosphorus');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim())! < 0) {
    return 'Phosphorus must not be negative.';
  }
  return null;
}

String? validatePotassium(String? text) {
  final numeric = _numericError(text, label: 'Potassium');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim())! < 0) {
    return 'Potassium must not be negative.';
  }
  return null;
}

String? validateElectricalConductivity(String? text) {
  final numeric = _numericError(text, label: 'Electrical Conductivity');
  if (numeric != null) return numeric;
  if (text == null || text.trim().isEmpty) return null;
  if (double.tryParse(text.trim())! < 0) {
    return 'Electrical Conductivity must not be negative.';
  }
  return null;
}

/// Non-blocking warnings for readings that look suspicious.
String? warningForTemperature(double? value, String unit) {
  if (value == null) return null;
  if (unit == '°F') {
    if (value > 140) return 'Unusually high temperature — please verify.';
  } else {
    if (value > 60) return 'Unusually high temperature — please verify.';
  }
  return null;
}

String? warningForFertility(double? value) {
  if (value == null) return null;
  if (value > 1000) return 'Unusually high fertility — please verify.';
  return null;
}
