import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:quantize_dart/quantize_dart.dart';

import 'convert_color.dart';

class ImageProcessing {
  static const int SIZE = 1200 * 1200;
  static const double DELTA = 15;

  bool checkTransparentColor(ImageProcessData data) {
    final pixels = data.imageData;

    for (var i = 0, offset; i < data.pixelCount; i++) {
      offset = i * 4;
      var r = pixels[offset + 0];
      var g = pixels[offset + 1];
      var b = pixels[offset + 2];
      var a = pixels[offset + 3];

      if (r > 255 && g > 255 && b > 255) continue;

      if (listEquals([r, g, b, a], [0, 0, 0, 0]) == true) {
        return true;
      }
    }
    return false;
  }

  Future<Map<List<int>, double>> getPaletteColor(ImageProcessData data,
      {int colorCount, double offset}) async {
    Map<List<int>, double> colorList = Map<List<int>, double>();
    var rgbList = _getRGBA(data, skipAlpha: true);

    CMap cMap = quantize(rgbList, colorCount);
    rgbList.every((color) {
      var mapColor = cMap.map(color);
      if (colorList.containsKey(mapColor)) {
        colorList[mapColor] += 1;
      } else {
        colorList.putIfAbsent(mapColor, () => 1);
      }

      return true;
    });

    colorList.forEach((key, value) {
      colorList[key] = (value / rgbList.length) * 100;
    });

    // var entries = colorList.entries.toList();

    // entries.sort(
    //     (MapEntry<List<int>, double> b, MapEntry<List<int>, double> a) =>
    //         a.value.compareTo(b.value));

    // colorList = Map<List<int>, double>.fromEntries(entries);

    colorList.removeWhere((key, value) => value < offset);

    return colorList;
  }

  bool _checkDeltaE(List<List<int>> checking, List<int> color) {
    return checking.every((item) {
      return deltaE(rgb2Lab(RGB(item[0], item[1], item[2])),
              rgb2Lab(RGB(color[0], color[1], color[2]))) >
          DELTA;
    });
  }

  bool _checkDifferentColor(List<RGB> checking, RGB color) {
    return checking.every((item) {
      return deltaE(rgb2Lab(item), rgb2Lab(color)) > DELTA;
    });
  }

  bool validateImageSize(Image image) {
    return getPixelCount(image) >= SIZE;
  }

  List<List<int>> _getRGBA(ImageProcessData data, {bool skipAlpha = false, int quality = 5}) {
    final pixels = data.imageData;
    List<List<int>> rgbaList = [];

    for (var i = 0, offset; i < data.pixelCount; i += quality) {
      offset = i * 4;
      var r = pixels[offset + 0];
      var g = pixels[offset + 1];
      var b = pixels[offset + 2];
      var a = pixels[offset + 3];

      if (skipAlpha && a < 125) continue;

      if (r > 255 && g > 255 && b > 255) continue;

      rgbaList.add([r, g, b, a]);
    }

    return rgbaList;
  }

  // bool checkNumberColors(ImageProcessData data) {
  //   var result = _checkColors(data);
  //   return result;
  // }

  int getPixelCount(Image image) {
    return image.width * image.height;
  }

  Future<Uint8List> getImageData(Image image) async {
    try {
      return image
          .toByteData(format: ImageByteFormat.rawRgba)
          .then((val) => Uint8List.view((val.buffer)));
    } catch (e) {
      return null;
    }
  }
}

class ColorPalette {
  Color color;
  double count;

  ColorPalette(this.color, this.count);
}

class RGB {
  int r;
  int g;
  int b;

  RGB(this.r, this.g, this.b);

  RGB.fromRGBA(RGBA rgba)
      : this.r = rgba.r,
        this.g = rgba.g,
        this.b = rgba.b;

  @override
  String toString() {
    return "[$r,$g,$b]";
  }
}

class RGBA {
  int r;
  int g;
  int b;
  int a;

  RGBA(this.r, this.g, this.b, this.a);

  @override
  String toString() {
    return "[$r,$g,$b,$a]";
  }
}

class ImageProcessData {
  dynamic imageData;
  int pixelCount;

  ImageProcessData({this.imageData, this.pixelCount});
}
