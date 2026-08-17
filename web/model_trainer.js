/* SFARM Admin Model Trainer engine.
 *
 * Trains an image classifier in the browser using TensorFlow.js:
 *   - MobileNetV2 feature extractor (tfjs-models, 1280-dim avg-pooled features)
 *   - Dense transfer-learning head trained on uploaded images
 *
 * The trained head is exported in TF.js format (model.json + weights.bin).
 * Convert it to the .tflite used by the mobile app via tools/convert_to_tflite.py
 * (rebuilds the full MobileNetV2 + head graph with the same preprocessing).
 */
(function () {
  'use strict';

  var MOBILENET_URL = 'https://storage.googleapis.com/tfjs-models/tfjs/mobilenet_v1_1.0_224/model.json';
  var EPOCHS = 50;

  var state = {
    ready: false,
    mobilenet: null,
    head: null,
    phase: 'idle',
    epoch: 0,
    totalEpochs: 0,
    loss: 0,
    acc: 0,
    classNames: [],
    sampleCounts: [],
  };

  async function init() {
    await tf.ready();
    if (!state.mobilenet) {
      state.mobilenet = await tf.loadLayersModel(MOBILENET_URL);
    }
    state.ready = true;
    return true;
  }

  function loadImage(dataUrl) {
    return new Promise(function (resolve, reject) {
      var img = new Image();
      img.onload = function () { resolve(img); };
      img.onerror = function () { reject(new Error('Could not decode image')); };
      img.src = dataUrl;
    });
  }

  async function extractFeatures(dataUrl) {
    var img = await loadImage(dataUrl);
    var tensor = tf.browser.fromPixels(img)
      .resizeBilinear([224, 224])
      .toFloat()
      .expandDims(0)
      .div(127.5)
      .sub(1);
    var features = state.mobilenet.predict(tensor);
    tensor.dispose();
    return features;
  }

  async function train(payloadJson) {
    var payload = JSON.parse(payloadJson);
    var classNames = payload.classes || [];
    var samples = payload.samples || [];

    await init();
    if (classNames.length < 2) {
      throw new Error('At least 2 classes are required.');
    }

    state.classNames = classNames;
    state.sampleCounts = samples.map(function (s) { return s ? s.length : 0; });
    state.phase = 'training';
    state.epoch = 0;
    state.totalEpochs = EPOCHS;
    state.loss = 0;
    state.acc = 0;

    var featureTensors = [];
    var labelIndices = [];
    var broken = [];

    for (var c = 0; c < samples.length; c++) {
      var urls = samples[c] || [];
      for (var i = 0; i < urls.length; i++) {
        try {
          var f = await extractFeatures(urls[i]);
          featureTensors.push(f);
          labelIndices.push(c);
        } catch (e) {
          broken.push(c);
        }
      }
    }

    if (featureTensors.length < classNames.length) {
      state.phase = 'idle';
      throw new Error('Not enough usable images to train (broken: ' + broken.length + ').');
    }

    var numClasses = classNames.length;
    var featureSize = featureTensors[0].shape[1];
    var featureConcat = tf.concat(featureTensors, 0);
    var oneHot = tf.oneHot(tf.tensor1d(labelIndices, 'int32'), numClasses);

    var input = tf.input({ shape: [featureSize] });
    var dense1 = tf.layers.dense({ units: 128, activation: 'relu' }).apply(input);
    var dropout = tf.layers.dropout({ rate: 0.3 }).apply(dense1);
    var output = tf.layers.dense({ units: numClasses, activation: 'softmax' }).apply(dropout);
    var head = tf.model({ inputs: input, outputs: output });

    head.compile({
      optimizer: tf.train.adam(0.001),
      loss: 'categoricalCrossentropy',
      metrics: ['accuracy'],
    });

    var totalSamples = featureTensors.length;

    await head.fit(featureConcat, oneHot, {
      epochs: EPOCHS,
      batchSize: Math.min(16, totalSamples),
      shuffle: true,
      callbacks: {
        onEpochEnd: function (epoch, logs) {
          state.epoch = epoch + 1;
          state.loss = logs.loss;
          state.acc = logs.acc;
        },
      },
    });

    featureConcat.dispose();
    oneHot.dispose();
    featureTensors.forEach(function (t) { t.dispose(); });

    state.head = head;
    state.phase = 'trained';

    return JSON.stringify({
      ok: true,
      classes: classNames,
      total: totalSamples,
      epochs: EPOCHS,
      loss: state.loss,
      acc: state.acc,
      broken: broken,
    });
  }

  function getStatus() {
    return JSON.stringify({
      ready: state.ready,
      phase: state.phase,
      epoch: state.epoch,
      totalEpochs: state.totalEpochs,
      loss: state.loss,
      acc: state.acc,
      classNames: state.classNames,
      sampleCounts: state.sampleCounts,
    });
  }

  async function exportHead() {
    if (!state.head) {
      throw new Error('Train the model first.');
    }
    await state.head.save('downloads://sfarm_trained_head');
    return JSON.stringify({ ok: true });
  }

  window.sfarmTrainer = {
    init: init,
    train: train,
    getStatus: getStatus,
    exportHead: exportHead,
  };
})();
