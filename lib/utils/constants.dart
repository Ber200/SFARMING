class AppConstants {
  // App Info
  static const String appName = 'SMARTFARMING';
  static const String appVersion = '1.0.0';
  
  // Disease Names
  static const String bacterialLeafBlight = 'Bacterial Leaf Blight';
  static const String brownSpot = 'Brown Spot';
  static const String sheathBlight = 'Sheath Blight';
  static const String healthyLeaf = 'Healthy Rice Leaf';
  
  // Soil Ranges
  static const double minOptimalPH = 5.5;
  static const double maxOptimalPH = 7.5;
  static const double minOptimalMoisture = 30.0;
  static const double maxOptimalMoisture = 70.0;
  
  // Weather
  static const String defaultCity = 'Panabo City';
  static const String defaultCountry = 'PH';
  static const double maxWindSpeedForSpraying = 15.0; // m/s
  
  // Model
  static const int modelInputSize = 224;
  static const String modelPath = 'assets/models/model_unquant.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  // Real-time scanner stability
  // Motion score (0..1) above which a frame counts as "moving". Tune through
  // testing: too low triggers Invalid during normal hand movement, too high
  // misses rapid shaking.
  static const double motionThreshold = 0.25;
  // Consecutive high-motion frames (at ~500ms each) before the scanner enters
  // the UNSTABLE state. Hysteresis prevents VALID/INVALID flickering.
  static const int motionEnterUnstableFrames = 3;
  // Consecutive low-motion frames before the scanner automatically resumes.
  static const int motionExitUnstableFrames = 5;
  // Real-time frame analysis interval in milliseconds.
  static const int scanFrameIntervalMs = 500;
}
