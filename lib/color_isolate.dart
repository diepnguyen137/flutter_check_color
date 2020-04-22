
import 'dart:isolate';

import 'package:sample_app/image_process.dart';

class DecodeParam {
  final ImageProcessData data;
  final SendPort sendPort;
  DecodeParam(this.data, this.sendPort);
}

void checkColor(DecodeParam param) async {
  final imageProcess = ImageProcessing();
  var result = await imageProcess.getPaletteColor(param.data, colorCount: 64, offset: 0.4);

  param.sendPort.send(result);
}