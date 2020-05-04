import 'dart:isolate';

import 'package:sample_app/image_process.dart';

class DecodeParam {
  final ImageProcessData data;
  final SendPort sendPort;
  DecodeParam(this.data, this.sendPort);
}

void checkColor(DecodeParam param) async {
  final imageProcess = ImageProcessing();
  var isTransparent = imageProcess.checkTransparentColor(param.data);
  if (isTransparent) {
    var result = await imageProcess.getPaletteColor(param.data,
        colorCount: 64, offset: 2);
    param.sendPort.send({'result': result});
  }
  param.sendPort.send(-1);
}
