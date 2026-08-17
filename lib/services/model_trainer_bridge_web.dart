import 'dart:convert';
import 'dart:js_interop';

/// Static-interop view of `window.sfarmTrainer` (web/model_trainer.js).
extension type _SfarmTrainer._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> init();
  external JSPromise<JSAny?> train(JSString payload);
  external JSPromise<JSAny?> getStatus();
  external JSPromise<JSAny?> exportHead();
}

/// Static-interop view of the global object, exposing `window.sfarmTrainer`.
extension type _GlobalContext._(JSObject _) implements JSObject {
  external JSObject? get sfarmTrainer;
}

/// Thrown when the `window.sfarmTrainer` JS API is not present.
class ModelTrainerUnavailableError implements Exception {
  final String message;
  const ModelTrainerUnavailableError(this.message);
  @override
  String toString() => 'ModelTrainerUnavailableError: $message';
}

_SfarmTrainer _requireTrainer() {
  final trainer = (globalContext as _GlobalContext).sfarmTrainer;
  if (trainer == null) {
    throw const ModelTrainerUnavailableError(
      'Model trainer engine not loaded. Please reload the page.',
    );
  }
  return trainer as _SfarmTrainer;
}

/// Loads the MobileNet feature extractor and warms up TensorFlow.js.
Future<void> initModelTrainer() async {
  final promise = _requireTrainer().init();
  await promise.toDart;
}

/// Trains the transfer-learning head on [samples] (data URLs per class).
///
/// Resolves when training completes; poll [getTrainerStatus] for progress.
Future<Map<String, dynamic>> trainModel({
  required List<String> classNames,
  required List<List<String>> samples,
}) async {
  final payload =
      jsonEncode({'classes': classNames, 'samples': samples}).toJS;
  final promise = _requireTrainer().train(payload);
  final result = await promise.toDart;
  return jsonDecode((result as JSString).toDart) as Map<String, dynamic>;
}

/// Current training state: phase, epoch/totalEpochs, loss, accuracy.
Future<Map<String, dynamic>> getTrainerStatus() async {
  final promise = _requireTrainer().getStatus();
  final result = await promise.toDart;
  return jsonDecode((result as JSString).toDart) as Map<String, dynamic>;
}

/// Triggers the TF.js model download (model.json + weights.bin) in the browser.
Future<void> exportHeadModel() async {
  final promise = _requireTrainer().exportHead();
  await promise.toDart;
}
