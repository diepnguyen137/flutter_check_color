import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_app/color_isolate.dart';
import 'package:sample_app/image_process.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _file;
  Map<List<int>, double> _colorMap = Map<List<int>, double>();
  ImageProcessing _imgProcess = ImageProcessing();
  List<ColorPalette> _colorPalette = [];
  List<Color> _colors = [];

  Future getImage() async {
    _colorPalette.clear();
    _file = await ImagePicker.pickImage(source: ImageSource.gallery);

    // final image = await decodeImageFromList(_file.readAsBytesSync());
    // List rgbColors = await getPaletteFromImage(await getImageFromProvider(FileImage(_file)), 4);
    // _colors = rgbColors.map((rgb) => Color.fromARGB(255, rgb[0], rgb[1], rgb[2])).toList();

    final image = await decodeImageFromList(_file.readAsBytesSync());
    var imageData = await _imgProcess.getImageData(image);
    var pixelCount = _imgProcess.getPixelCount(image);

    var receivePort = ReceivePort();
    var colorIsolate = await Isolate.spawn(
        checkColor,
        DecodeParam(
            ImageProcessData(imageData: imageData, pixelCount: pixelCount),
            receivePort.sendPort));

    // // Get the processed image from the isolate.
    receivePort.listen((msg) {
      if (msg == -1) {
        print("Image not transparent");
        colorIsolate.kill(priority: Isolate.immediate);
        return;
      } else {
        _colorMap = msg['result'];
        _colorMap.forEach((key, value) {
          _colorPalette.add(
              ColorPalette(Color.fromARGB(255, key[0], key[1], key[2]), value));
        });

        colorIsolate.kill(priority: Isolate.immediate);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _file == null
          ? Text('No image selected.')
          : ListView(
              children: <Widget>[
                Image.file(_file),
                Wrap(
                    children: _colorPalette
                        .map(
                          (item) => _itemColor(item.color, item.count),
                        )
                        .toList()),
                Wrap(
                    children: _colors
                        .map(
                          (color) => Container(
                            width: 40,
                            height: 40,
                            color: color,
                          ),
                        )
                        .toList())
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _itemColor(Color color, double count) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            color: color,
          ),
          Text("[${count.toString()}]")
        ],
      ),
    );
  }
}
