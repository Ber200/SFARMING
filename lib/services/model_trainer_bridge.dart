// Conditional import: web implementation (js_interop) on web, stub elsewhere.
// Admin is web-only; the stub keeps the farmer (mobile) build compiling.
export 'model_trainer_bridge_stub.dart'
    if (dart.library.js_interop) 'model_trainer_bridge_web.dart';
