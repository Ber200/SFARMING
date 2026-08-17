class SoilDataModel {
  final String userId;
  final double? ph;
  final double? moisture; // percentage
  final double? humidity; // air relative humidity percentage
  final String? status; // 'OK', 'LOW', 'HIGH'
  final String? description;
  final DateTime timestamp;

  // Sensor scan readings (from the Soil Sensor Screen Scanner).
  final double? fertility; // electrical conductivity, µS/cm
  final double? electricalConductivity; // EC (µS/cm or mS/cm)
  final double? nitrogen; // N (mg/kg or ppm)
  final double? phosphorus; // P (mg/kg or ppm)
  final double? potassium; // K (mg/kg or ppm)
  final double? temperature; // soil temperature in the detected unit
  final String? temperatureUnit; // '°C' or '°F'
  final double? sunlight; // LUX
  final String? source; // e.g. 'device_scan' or 'manual'
  final bool? verifiedByFarmer; // true when confirmed by farmer
  final String? scanImage; // URL of the captured sensor-screen image

  SoilDataModel({
    required this.userId,
    this.ph,
    this.moisture,
    this.humidity,
    this.status,
    this.description,
    required this.timestamp,
    this.fertility,
    this.electricalConductivity,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.temperature,
    this.temperatureUnit,
    this.sunlight,
    this.source,
    this.verifiedByFarmer,
    this.scanImage,
  });

  factory SoilDataModel.fromMap(Map<String, dynamic> map) {
    return SoilDataModel(
      userId: map['userId'] ?? '',
      ph: map['ph'] != null ? (map['ph'] as num).toDouble() : null,
      moisture: map['moisture'] != null ? (map['moisture'] as num).toDouble() : null,
      humidity: map['humidity'] != null ? (map['humidity'] as num).toDouble() : null,
      status: map['status'],
      description: map['description'],
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      fertility: map['fertility'] != null ? (map['fertility'] as num).toDouble() : null,
      electricalConductivity: map['electricalConductivity'] != null
          ? (map['electricalConductivity'] as num).toDouble()
          : (map['fertility'] != null ? (map['fertility'] as num).toDouble() : null),
      nitrogen: map['nitrogen'] != null ? (map['nitrogen'] as num).toDouble() : null,
      phosphorus: map['phosphorus'] != null ? (map['phosphorus'] as num).toDouble() : null,
      potassium: map['potassium'] != null ? (map['potassium'] as num).toDouble() : null,
      temperature: map['temperature'] != null ? (map['temperature'] as num).toDouble() : null,
      temperatureUnit: map['temperatureUnit'],
      sunlight: map['sunlight'] != null ? (map['sunlight'] as num).toDouble() : null,
      source: map['source'],
      verifiedByFarmer: map['verifiedByFarmer'] as bool?,
      scanImage: map['scanImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ph': ph,
      'moisture': moisture,
      'humidity': humidity,
      'status': status,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'fertility': fertility ?? electricalConductivity,
      'electricalConductivity': electricalConductivity ?? fertility,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'temperature': temperature,
      'temperatureUnit': temperatureUnit,
      'sunlight': sunlight,
      'source': source,
      'verifiedByFarmer': verifiedByFarmer,
      'scanImage': scanImage,
    };
  }

  String get phStatus {
    if (ph == null) return 'Unknown';
    if (ph! < 5.5) return 'Too Acidic';
    if (ph! > 7.5) return 'Too Alkaline';
    return 'Optimal';
  }

  String get moistureStatus {
    if (moisture == null) return 'Unknown';
    if (moisture! < 30) return 'Low';
    if (moisture! > 70) return 'High';
    return 'Optimal';
  }
  
  String get calculatedStatus {
    if (status != null) return status!;
    return moistureStatus;
  }
  
  String get recommendation {
    if (moisture == null) return 'No moisture data available';
    if (moisture! < 30) {
      return 'Soil moisture is LOW. Consider irrigation to maintain optimal growing conditions.';
    } else if (moisture! > 70) {
      return 'Soil moisture is HIGH. Monitor for waterlogging and ensure proper drainage.';
    }
    return 'Soil moisture is optimal for rice cultivation.';
  }
  
  String get diseaseRelationshipDescription {
    if (moisture == null && ph == null) {
      return 'Complete soil data analysis to understand disease risk factors.';
    }
    
    String description = '';
    
    // Moisture and disease relationship
    if (moisture != null) {
      if (moisture! < 30) {
        description += '⚠️ LOW MOISTURE IMPACT:\n';
        description += '• Dry soil conditions can stress rice plants, making them more susceptible to diseases.\n';
        description += '• Low moisture increases risk of Brown Spot disease.\n';
        description += '• Plants under water stress are weaker and less resistant to pathogens.\n';
        description += '• Maintain adequate irrigation to prevent disease outbreaks.\n\n';
      } else if (moisture! > 70) {
        description += '⚠️ HIGH MOISTURE IMPACT:\n';
        description += '• Excessive moisture creates favorable conditions for fungal diseases.\n';
        description += '• High moisture increases risk of Sheath Blight and Bacterial Leaf Blight.\n';
        description += '• Waterlogged soil reduces root health and plant immunity.\n';
        description += '• Ensure proper drainage to prevent disease spread.\n\n';
      } else {
        description += '✅ OPTIMAL MOISTURE:\n';
        description += '• Current moisture levels are ideal for healthy rice growth.\n';
        description += '• Optimal moisture helps maintain plant immunity against diseases.\n';
        description += '• Continue monitoring to maintain this range.\n\n';
      }
    }
    
    // pH and disease relationship
    if (ph != null) {
      if (ph! < 5.5) {
        description += '⚠️ ACIDIC SOIL IMPACT:\n';
        description += '• Acidic soil (pH < 5.5) can stress rice plants.\n';
        description += '• Low pH may increase susceptibility to certain diseases.\n';
        description += '• Consider soil amendment with lime to raise pH.\n\n';
      } else if (ph! > 7.5) {
        description += '⚠️ ALKALINE SOIL IMPACT:\n';
        description += '• Alkaline soil (pH > 7.5) affects nutrient availability.\n';
        description += '• High pH can lead to nutrient deficiencies, weakening plants.\n';
        description += '• Weakened plants are more prone to disease infections.\n';
        description += '• Consider soil amendments to adjust pH to optimal range (5.5-7.5).\n\n';
      } else {
        description += '✅ OPTIMAL pH:\n';
        description += '• pH level is within optimal range for rice cultivation.\n';
        description += '• Optimal pH ensures proper nutrient uptake and plant health.\n\n';
      }
    }
    
    return description.trim();
  }
}
