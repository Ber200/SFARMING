// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

bool _iframeRegistered = false;
const String _viewType = 'model-trainer-html-iframe';

Widget buildModelTrainerIframe() {
  if (!_iframeRegistered) {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'model_trainer.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      },
    );
    _iframeRegistered = true;
  }
  return const HtmlElementView(viewType: _viewType);
}


