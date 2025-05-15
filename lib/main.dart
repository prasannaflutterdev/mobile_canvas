// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
//
// void main() => runApp(CanvasEditorApp());
//
// class CanvasEditorApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Canvas Editor',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: CanvasEditorHome(),
//     );
//   }
// }
//
// class CanvasEditorHome extends StatefulWidget {
//   @override
//   _CanvasEditorHomeState createState() => _CanvasEditorHomeState();
// }
//
// class _CanvasEditorHomeState extends State<CanvasEditorHome> {
//   TransformationController _transformationController = TransformationController();
//   List<CanvasElement> _elements = [];
//   Offset? _start;
//   String _selectedTool = 'pen';
//   Color _textColor = Colors.black; // Default color for text
//   CanvasElement? _selectedElement;
//   final ImagePicker _picker = ImagePicker();
//   double _resizeFactor = 1.0;
//
//   void _selectTool(String tool) => setState(() => _selectedTool = tool);
//
//   void _onPanStart(DragStartDetails details) {
//     final pos = _transformationController.toScene(details.localPosition);
//     if (_selectedTool == 'pen') {
//       setState(() => _start = pos);
//     } else if (_selectedElement != null && _selectedElement is TextElement) {
//       // Select and drag the text element for moving
//     }
//   }
//
//   void _onPanUpdate(DragUpdateDetails details) {
//     final pos = _transformationController.toScene(details.localPosition);
//     if (_start != null && _selectedTool == 'pen') {
//       setState(() {
//         _elements.add(LineElement(start: _start!, end: pos, position: null));
//         _start = pos;
//       });
//     } else if (_selectedElement != null && _selectedElement is TextElement) {
//       // Update position for the selected element
//       setState(() {
//         _selectedElement?.position = pos;
//       });
//     }
//   }
//
//   void _onPanEnd(DragEndDetails details) => setState(() => _start = null);
//
//   Future<void> _addText() async {
//     showDialog(
//       context: context,
//       builder: (context) {
//         TextEditingController textController = TextEditingController();
//         double fontSize = 24;
//
//         return AlertDialog(
//           title: Text("Add/Edit Text"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(controller: textController, decoration: InputDecoration(labelText: 'Text')),
//               SizedBox(height: 8),
//               Slider(
//                 value: fontSize,
//                 min: 8,
//                 max: 64,
//                 onChanged: (value) => setState(() => fontSize = value),
//                 label: "Font Size: \$fontSize",
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: () async {
//                   final result = await showDialog<Color>(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: Text("Pick Text Color"),
//                       content: SingleChildScrollView(
//                         child: ColorPicker(
//                           initialColor: _textColor,
//                           onColorChanged: (color) => setState(() => _textColor = color),
//                         ),
//                       ),
//                     ),
//                   );
//                   if (result != null) setState(() => _textColor = result);
//                 },
//                 child: Text("Select Color"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   _elements.add(TextElement(
//                     text: textController.text,
//                     position: Offset(100, 100),
//                     style: TextStyle(fontSize: fontSize, color: _textColor),
//                   ));
//                 });
//                 Navigator.of(context).pop();
//               },
//               child: Text("Add"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       final imageData = await image.readAsBytes();
//       final uiImage = await decodeImageFromList(imageData);
//       setState(() => _elements.add(ImageElement(image: uiImage, position: null)));
//     }
//   }
//
//   Future<void> _exportCanvas() async {
//     // Save the canvas image to the device
//     final directory = await getApplicationDocumentsDirectory();
//     final filePath = path.join(directory.path, 'canvas_export.png');
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(400, 400)));
//     final painter = CanvasPainter(_elements, onTap: (CanvasElement ) {  });
//     painter.paint(canvas, Size(400, 400));
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(400, 400);
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     final buffer = byteData!.buffer.asUint8List();
//     final file = File(filePath);
//     await file.writeAsBytes(buffer);
//     print("Canvas exported to $filePath");
//   }
//
//   void _selectElement(CanvasElement element) {
//     setState(() {
//       _selectedElement = element;
//     });
//   }
//
//   void _resizeSelectedElement(double factor) {
//     if (_selectedElement is TextElement) {
//       setState(() {
//         _selectedElement = TextElement(
//           text: (_selectedElement as TextElement).text,
//           position: (_selectedElement as TextElement).position,
//           style: TextStyle(
//             fontSize: (_selectedElement as TextElement).style.fontSize! * factor,
//             color: (_selectedElement as TextElement).style.color,
//           ),
//         );
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Canvas Editor')),
//       body: GestureDetector(
//         onPanStart: _onPanStart,
//         onPanUpdate: _onPanUpdate,
//         onPanEnd: _onPanEnd,
//         child: CustomPaint(
//           size: Size.infinite,
//           painter: CanvasPainter(_elements, onTap: _selectElement),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addText,
//         child: Icon(Icons.text_fields),
//       ),
//       bottomNavigationBar: BottomAppBar(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             IconButton(onPressed: () => _selectTool('pen'), icon: Icon(Icons.edit)),
//             IconButton(onPressed: () => _selectTool('text'), icon: Icon(Icons.text_fields)),
//             IconButton(onPressed: _pickImage, icon: Icon(Icons.image)),
//             IconButton(onPressed: _exportCanvas, icon: Icon(Icons.download)),
//             IconButton(
//               onPressed: () {
//                 if (_selectedElement != null) {
//                   setState(() {
//                     _resizeFactor = _resizeFactor == 1.0 ? 1.5 : 1.0;
//                     _resizeSelectedElement(_resizeFactor);
//                   });
//                 }
//               },
//               icon: Icon(Icons.aspect_ratio),
//             ),
//             IconButton(
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: Text("Layers"),
//                     content: SingleChildScrollView(
//                       child: Column(
//                         children: _elements.map((e) {
//                           return ListTile(
//                             title: Text(e.runtimeType.toString()),
//                             onTap: () => _selectElement(e),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         child: Text("Close"),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               icon: Icon(Icons.layers),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ColorPicker extends StatefulWidget {
//   final Color initialColor;
//   final ValueChanged<Color> onColorChanged;
//
//   ColorPicker({required this.initialColor, required this.onColorChanged});
//
//   @override
//   _ColorPickerState createState() => _ColorPickerState();
// }
//
// class _ColorPickerState extends State<ColorPicker> {
//   late Color _selectedColor;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedColor = widget.initialColor;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ColorPickerDialog(
//       initialColor: _selectedColor,
//       onColorChanged: (color) {
//         setState(() {
//           _selectedColor = color;
//         });
//         widget.onColorChanged(color);
//       },
//     );
//   }
// }
//
// class ColorPickerDialog extends StatelessWidget {
//   final Color initialColor;
//   final ValueChanged<Color> onColorChanged;
//
//   ColorPickerDialog({required this.initialColor, required this.onColorChanged});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ColorPickerSlider(
//           label: 'Red',
//           value: initialColor.red.toDouble(),
//           onChanged: (value) => onColorChanged(Color.fromARGB(initialColor.alpha, value.toInt(), initialColor.green, initialColor.blue)),
//         ),
//         ColorPickerSlider(
//           label: 'Yellow',
//           value: initialColor.green.toDouble(),
//           onChanged: (value) => onColorChanged(Color.fromARGB(initialColor.alpha, initialColor.red, value.toInt(), initialColor.blue)),
//         ),
//         ColorPickerSlider(
//           label: 'Blue',
//           value: initialColor.blue.toDouble(),
//           onChanged: (value) => onColorChanged(Color.fromARGB(initialColor.alpha, initialColor.red, initialColor.green, value.toInt())),
//         ),
//         SizedBox(height: 16),
//         Container(
//           width: 100,
//           height: 100,
//           color: initialColor,
//         ),
//       ],
//     );
//   }
// }
//
// class ColorPickerSlider extends StatelessWidget {
//   final String label;
//   final double value;
//   final ValueChanged<double> onChanged;
//
//   ColorPickerSlider({
//     required this.label,
//     required this.value,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Text(label),
//         Slider(
//           value: value,
//           min: 0,
//           max: 255,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
// }
//
// abstract class CanvasElement {
//   Offset position;
//   CanvasElement({required this.position});
// }
//
// class LineElement extends CanvasElement {
//   final Offset start;
//   final Offset end;
//
//   LineElement({required this.start, required this.end, required Offset position}) : super(position: position);
// }
//
// class TextElement extends CanvasElement {
//   String text;
//   TextStyle style;
//
//   @override
//   final position;
//
//   TextElement({required this.text, required this.position, required this.style}) : super(position: position);
// }
//
// class ImageElement extends CanvasElement {
//   final ui.Image image;
//
//   ImageElement({required this.image, required Offset position}) : super(position: position);
// }
//
// class CanvasPainter extends CustomPainter {
//   final List<CanvasElement> elements;
//   final Function(CanvasElement) onTap;
//   CanvasPainter(this.elements, {required this.onTap});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..strokeWidth = 4.0..strokeCap = StrokeCap.round;
//
//     for (var element in elements) {
//       if (element is LineElement) {
//         paint.color = Colors.blue;
//         canvas.drawLine(element.start, element.end, paint);
//       } else if (element is TextElement) {
//         final textPainter = TextPainter(
//           text: TextSpan(text: element.text, style: element.style),
//           textDirection: TextDirection.ltr,
//         );
//         textPainter.layout();
//         textPainter.paint(canvas, element.position);
//       } else if (element is ImageElement) {
//         canvas.drawImage(element.image, element.position, paint);
//       }
//
//       // Add interaction area for tap events
//       final rect = Rect.fromLTWH(element.position.dx - 10, element.position.dy - 10, 100, 50);
//       canvas.drawRect(rect, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() => runApp(CanvasEditorApp());

class CanvasEditorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Canvas Editor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CanvasEditorHome(),
    );
  }
}

class CanvasEditorHome extends StatefulWidget {
  @override
  _CanvasEditorHomeState createState() => _CanvasEditorHomeState();
}

class _CanvasEditorHomeState extends State<CanvasEditorHome> {
  TransformationController _transformationController = TransformationController();
  List<CanvasElement> _elements = [];
  Offset? _start;
  String _selectedTool = 'pen';
  Color _textColor = Colors.black; // Default color for text
  final ImagePicker _picker = ImagePicker();

  void _selectTool(String tool) => setState(() => _selectedTool = tool);

  void _onPanStart(DragStartDetails details) {
    final pos = _transformationController.toScene(details.localPosition);
    if (_selectedTool == 'pen') {
      setState(() => _start = pos);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = _transformationController.toScene(details.localPosition);
    if (_start != null && _selectedTool == 'pen') {
      setState(() {
        _elements.add(LineElement(start: _start!, end: pos));
        _start = pos;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) => setState(() => _start = null);

  Future<void> _addText() async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController textController = TextEditingController();
        double fontSize = 24;

        return AlertDialog(
          title: Text("Add/Edit Text"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textController, decoration: InputDecoration(labelText: 'Text')),
              SizedBox(height: 8),
              Slider(
                value: fontSize,
                min: 8,
                max: 64,
                onChanged: (value) => setState(() => fontSize = value),
                label: "Font Size: \$fontSize",
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<Color>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Pick Text Color"),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          initialColor: _textColor,
                          onColorChanged: (color) => setState(() => _textColor = color),
                        ),
                      ),
                    ),
                  );
                  if (result != null) setState(() => _textColor = result);
                },
                child: Text("Select Color"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _elements.add(TextElement(
                    text: textController.text,
                    position: Offset(100, 100),
                    style: TextStyle(fontSize: fontSize, color: _textColor),
                  ));
                });
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageData = await image.readAsBytes();
      final uiImage = await decodeImageFromList(imageData);
      setState(() => _elements.add(ImageElement(image: uiImage)));
    }
  }

  Future<void> _exportCanvas() async {
    try {
      // Get the Downloads directory
      final directory = Directory('/storage/emulated/0/Download');

      // Generate a unique filename with a timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(directory.path, 'canvas_export_$timestamp.png');

      // Start recording the canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(400, 400)));

      // Paint the canvas with the elements
      final painter = CanvasPainter(_elements);
      painter.paint(canvas, Size(400, 400));
      final picture = recorder.endRecording();

      // Convert the canvas to an image
      final img = await picture.toImage(400, 400);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Save the image as a file
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      // Show success toast message
      Fluttertoast.showToast(
        msg: "Canvas exported to $filePath",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      print("Canvas exported to $filePath");
    } catch (e) {
      // Show error toast message
      Fluttertoast.showToast(
        msg: "Failed to export canvas: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print("Error exporting canvas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Canvas Editor')),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          size: Size.infinite,
          painter: CanvasPainter(_elements),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addText,
        child: Icon(Icons.text_fields),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () => _selectTool('pen'), icon: Icon(Icons.edit)),
            IconButton(onPressed: () => _selectTool('text'), icon: Icon(Icons.text_fields)),
            IconButton(onPressed: _pickImage, icon: Icon(Icons.image)),
            IconButton(onPressed: _exportCanvas, icon: Icon(Icons.download)),
          ],
        ),
      ),
    );
  }
}

class ColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  ColorPicker({required this.initialColor, required this.onColorChanged});

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return ColorPickerDialog(
      initialColor: _selectedColor,
      onColorChanged: (color) {
        setState(() {
          _selectedColor = color;
        });
        widget.onColorChanged(color);
      },
    );
  }
}

class ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  ColorPickerDialog({required this.initialColor, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColorPickerSlider(
          label: 'Red',
          value: initialColor.red.toDouble(),
          onChanged: (value) => onColorChanged(Color.fromARGB(initialColor.alpha, value.toInt(), initialColor.green, initialColor.blue)),
        ),
        ColorPickerSlider(
          label: 'Green',
          value: initialColor.green.toDouble(),
          onChanged: (value) => onColorChanged(Color.fromARGB(initialColor.alpha, initialColor.red, value.toInt(), initialColor.blue)),
        ),
        ColorPickerSlider(
          label: 'Blue',
          value: initialColor.blue.toDouble(),
          onChanged: (value) => onColorChanged(Color.fromARGB(initialColor.alpha, initialColor.red, initialColor.green, value.toInt())),
        ),
      ],
    );
  }
}

class ColorPickerSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  ColorPickerSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        Slider(
          value: value,
          min: 0,
          max: 255,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

abstract class CanvasElement {}

class LineElement extends CanvasElement {
  final Offset start;
  final Offset end;
  LineElement({required this.start, required this.end});
}

class TextElement extends CanvasElement {
  String text;
  Offset position;
  TextStyle style;

  TextElement({required this.text, required this.position, required this.style});
}

class ImageElement extends CanvasElement {
  final ui.Image image;
  ImageElement({required this.image});
}

class CanvasPainter extends CustomPainter {
  final List<CanvasElement> elements;
  CanvasPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 4.0..strokeCap = StrokeCap.round;

    for (var element in elements) {
      if (element is LineElement) {
        paint.color = Colors.blue;
        canvas.drawLine(element.start, element.end, paint);
      } else if (element is TextElement) {
        final textPainter = TextPainter(
          text: TextSpan(text: element.text, style: element.style),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, element.position);
      } else if (element is ImageElement) {
        canvas.drawImage(element.image, Offset.zero, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
