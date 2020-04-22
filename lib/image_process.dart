import 'dart:typed_data';
import 'dart:ui';
import 'package:quantize_dart/quantize_dart.dart';

import 'convert_color.dart';

class ImageProcessing {
  static const int SIZE = 1200 * 1200;
  static const double DELTA = 15;
  List<RGBA> _rgbaList = [];

  Future<Map<List<int>, double>> getPaletteColor(ImageProcessData data,
      {int colorCount, double offset}) async {
    Map<List<int>, double> colorList = Map<List<int>, double>();
    Map<List<int>, double> colorList2 = Map<List<int>, double>();

    var rgbList = _getRGBA(data, skipAlpha: true);

    CMap cMap = quantize(rgbList, colorCount);

    // rgbList.every((item) {
    //   // var rgb = RGB(item.r, item.g, item.b);

    //   // if (checking.length > 4) return false;

    //   if (_checkDeltaE(colorList.keys.toList(), item)) {
    //     colorList.putIfAbsent(item, () => 1);
    //   }

    //   return true;
    // });

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

    var entries = colorList.entries.toList();
    entries.sort(
        (MapEntry<List<int>, double> b, MapEntry<List<int>, double> a) =>
            a.value.compareTo(b.value));

    colorList = Map<List<int>, double>.fromEntries(entries);

    // colorList.keys.every((rgb) {
    //   if (_checkDeltaE(colorList2.keys.toList(), rgb)) {
    //     colorList2.putIfAbsent(rgb, () => 1);
    //   }

    //   return true;
    // });

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

  bool checkTransparentColor(ImageProcessData data) {
    return false;
    // _rgbaList = _getRGBA(data);

    // return _rgbaList.any((color) =>
    //     listEquals([color.r, color.g, color.b, color.a], [0, 0, 0, 0]));
  }

  List<List<int>> _getRGBA(ImageProcessData data, {bool skipAlpha = false}) {
    final pixels = data.imageData;
    List<List<int>> rgbaList = [];

    for (var i = 0, offset; i < data.pixelCount; i++) {
      offset = i * 4;
      var r = pixels[offset + 0];
      var g = pixels[offset + 1];
      var b = pixels[offset + 2];
      var a = pixels[offset + 3];

      if (skipAlpha && a < 125) continue;

      if ([r, g, b].every((color) => color > 255)) continue;

      rgbaList.add([r, g, b, a]);
    }

    return rgbaList;
  }

  // List<RGBA> _getRGBA(ImageProcessData data, {bool skipAlpha = false}) {
  //   final pixels = data.imageData;
  //   List<RGBA> rgbaList = [];

  //   for (var i = 0, offset; i < data.pixelCount; i++) {
  //     offset = i * 4;
  //     var r = pixels[offset + 0];
  //     var g = pixels[offset + 1];
  //     var b = pixels[offset + 2];
  //     var a = pixels[offset + 3];

  //     if (skipAlpha && a < 125) continue;

  //     if ([r, g, b].every((color) => color > 250)) continue;

  //     rgbaList.add(RGBA(r, g, b, a));
  //   }

  //   return rgbaList;
  // }

  bool checkNumberColors(ImageProcessData data) {
    var result = _checkColors(data);
    return result;
  }

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

  bool _checkColors(ImageProcessData data) {
    List<RGB> checking = [];
    var rgbList = _rgbaList.where((item) => item.a >= 125).toList();

    return rgbList.every((item) {
      var rgb = RGB(item.r, item.g, item.b);

      if (checking.length > 4) return false;

      if (_checkDifferentColor(checking, rgb)) {
        checking.add(rgb);
      }

      return true;
    });
  }

  List<RGBA> checkColors({ImageProcessData data}) {
    List<RGBA> checking = [];
    var rgbList = _rgbaList.where((item) => item.a >= 125).toList();
    // var rgbList = _getRGBA(data,skipAlpha: true);
    rgbList.every((item) {
      var rgb = RGB(item.r, item.g, item.b);

      // if (checking.length > 1200) return false;

      if (_checkDifferentColor2(checking, rgb)) {
        checking.add(item);
      }

      return true;
    });

    return checking;
  }

  bool _checkDifferentColor2(List<RGBA> checking, RGB color) {
    return checking.every((item) {
      return deltaE(rgb2Lab(RGB.fromRGBA(item)), rgb2Lab(color)) > DELTA;
    });
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
