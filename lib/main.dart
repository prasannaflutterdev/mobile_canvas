import 'package:flutter/material.dart';
import 'package:mobile_canvas/screens/canvas_size_selector.dart';


void main() => runApp(const CanvasEditorApp());

class CanvasEditorApp extends StatelessWidget {
  const CanvasEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Canvas Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CanvasSizeSelector(),
    );
  }
}

