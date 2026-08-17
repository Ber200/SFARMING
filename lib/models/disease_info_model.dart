class DiseaseInfoModel {
  final String name;
  final String description;
  final List<String> causes;
  final List<String> symptoms;
  final List<String> prevention;
  final String treatmentProtocol;

  DiseaseInfoModel({
    required this.name,
    required this.description,
    required this.causes,
    required this.symptoms,
    required this.prevention,
    required this.treatmentProtocol,
  });

  static DiseaseInfoModel getBacterialLeafBlight() {
    return DiseaseInfoModel(
      name: 'Bacterial Leaf Blight',
      description: 'A bacterial disease caused by Xanthomonas oryzae pv. oryzae that affects rice plants.',
      causes: [
        'Infected seeds',
        'Contaminated irrigation water',
        'High humidity and temperature',
        'Wounded leaves',
      ],
      symptoms: [
        'Water-soaked lesions on leaf margins',
        'Yellowing and wilting of leaves',
        'White to gray exudates on lesions',
        'Leaf death and plant stunting',
      ],
      prevention: [
        'Use disease-free seeds',
        'Practice crop rotation',
        'Avoid overhead irrigation',
        'Maintain proper plant spacing',
      ],
      treatmentProtocol: 'Apply copper-based bactericides (e.g., Copper Hydroxide) at 7-10 day intervals. Remove and destroy infected plants. Improve field drainage.',
    );
  }

  static DiseaseInfoModel getBrownSpot() {
    return DiseaseInfoModel(
      name: 'Brown Spot',
      description: 'A fungal disease caused by Cochliobolus miyabeanus that affects rice leaves and grains.',
      causes: [
        'Infected seeds',
        'High humidity',
        'Nutrient deficiency (especially silicon)',
        'Poor soil conditions',
      ],
      symptoms: [
        'Small brown spots on leaves',
        'Spots enlarge and become oval',
        'Yellow halos around spots',
        'Grain discoloration',
      ],
      prevention: [
        'Use resistant varieties',
        'Apply silicon fertilizers',
        'Maintain proper nutrition',
        'Practice field sanitation',
      ],
      treatmentProtocol: 'Apply fungicides containing Propiconazole or Tricyclazole. Foliar spray at 2-3 week intervals. Ensure adequate nitrogen and silicon levels.',
    );
  }

  static DiseaseInfoModel getSheathBlight() {
    return DiseaseInfoModel(
      name: 'Sheath Blight',
      description: 'A fungal disease caused by Rhizoctonia solani that affects rice sheaths and leaves.',
      causes: [
        'High plant density',
        'High humidity',
        'Excessive nitrogen',
        'Infected plant debris',
      ],
      symptoms: [
        'Oval or irregular lesions on sheaths',
        'Lesions with gray centers',
        'Leaf yellowing',
        'Plant lodging',
      ],
      prevention: [
        'Maintain proper plant spacing',
        'Avoid excessive nitrogen',
        'Remove infected plant debris',
        'Improve field aeration',
      ],
      treatmentProtocol: 'Apply fungicides like Validamycin or Azoxystrobin. Spray at booting stage and repeat after 10-14 days. Reduce nitrogen application.',
    );
  }

  static DiseaseInfoModel getHealthy() {
    return DiseaseInfoModel(
      name: 'Healthy Rice Leaf',
      description: 'The rice leaf shows no signs of disease and appears healthy.',
      causes: [],
      symptoms: [
        'Green, vibrant leaves',
        'No lesions or spots',
        'Normal growth pattern',
      ],
      prevention: [
        'Continue good agricultural practices',
        'Regular monitoring',
        'Maintain proper nutrition',
        'Preventive treatments as needed',
      ],
      treatmentProtocol: 'No treatment needed. Continue monitoring and maintain good agricultural practices.',
    );
  }

  static DiseaseInfoModel? getDiseaseInfo(String diseaseName) {
    switch (diseaseName.toLowerCase()) {
      case 'bacterial leaf blight':
        return getBacterialLeafBlight();
      case 'brown spot':
        return getBrownSpot();
      case 'sheath blight':
        return getSheathBlight();
      case 'healthy rice leaf':
      case 'healthy leaf':
      case 'healthy':
        return getHealthy();
      case 'invalid':
        return getInvalid();
      default:
        return null;
    }
  }

  /// Info for unrecognized / non-leaf images (model output class "Invalid")
  static DiseaseInfoModel getInvalid() {
    return DiseaseInfoModel(
      name: 'Invalid / Unrecognized',
      description: 'The leaf disease detector could not confidently identify a rice leaf in this image. '
          'The photo may contain a non-leaf object, be blurry, or have poor lighting.',
      causes: [
        'Image does not contain a rice leaf',
        'Photo is blurry or out of focus',
        'Poor lighting conditions',
        'Leaf is obstructed or partially visible',
      ],
      symptoms: [],
      prevention: [
        'Ensure the rice leaf fills most of the frame',
        'Use good lighting (natural daylight is best)',
        'Keep the camera steady and focused',
        'Avoid capturing soil, hands, or other objects',
      ],
      treatmentProtocol: 'No treatment needed. Please retake the photo following the tips above for accurate disease detection.',
    );
  }

  /// All diseases available for treatment dropdown (excludes Healthy)
  static List<DiseaseInfoModel> getAllDiseasesForTreatment() {
    return [
      getBacterialLeafBlight(),
      getBrownSpot(),
      getSheathBlight(),
    ];
  }
}
