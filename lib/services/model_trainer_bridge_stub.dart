/// Non-web stub: the model trainer only runs in the admin web app.
Future<void> initModelTrainer() async {
  throw UnsupportedError('Model trainer is only available on the admin web app.');
}

Future<Map<String, dynamic>> trainModel({
  required List<String> classNames,
  required List<List<String>> samples,
}) async {
  throw UnsupportedError('Model trainer is only available on the admin web app.');
}

Future<Map<String, dynamic>> getTrainerStatus() async {
  throw UnsupportedError('Model trainer is only available on the admin web app.');
}

Future<void> exportHeadModel() async {
  throw UnsupportedError('Model trainer is only available on the admin web app.');
}
