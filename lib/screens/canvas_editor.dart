import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/canvas_element.dart';
import '../models/shape_element.dart';
import '../models/path_element.dart';
import '../widgets/canvas_painter.dart';
import '../widgets/color_picker.dart';

class CanvasEditorScreen extends StatefulWidget {
  final double canvasWidth;
  final double canvasHeight;

  const CanvasEditorScreen({
    super.key,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  _CanvasEditorScreenState createState() => _CanvasEditorScreenState();
}

class _CanvasEditorScreenState extends State<CanvasEditorScreen> {
  final TransformationController _transformationController = TransformationController();
  final List<CanvasElement> _elements = [];
  final ImagePicker _picker = ImagePicker();

  String _selectedTool = 'select';
  CanvasElement? _selectedElement;
  Color _selectedColor = Colors.black;
  Color _selectedFillColor = Colors.transparent;
  double _strokeWidth = 2.0;
  double _canvasScale = 1.0;
  
  PathElement? _currentPath;
  ShapeElement? _currentShape;
  Offset? _startPoint;
  bool _isResizing = false;
  ResizeHandle? _activeHandle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _exportCanvas,
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showLayersDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                width: widget.canvasWidth,
                height: widget.canvasHeight,
                color: Colors.white,
                child: CustomPaint(
                  painter: CanvasPainter(
                    elements: _elements,
                    selectedElement: _selectedElement,
                    showHandles: _selectedElement != null && !_isResizing,
                  ),
                ),
              ),
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Positioned(
      left: 16,
      top: 16,
      child: Column(
        children: [
          _buildToolButton(Icons.pan_tool, 'select'),
          _buildToolButton(Icons.edit, 'pen'),
          _buildToolButton(Icons.rectangle_outlined, 'rectangle'),
          _buildToolButton(Icons.circle_outlined, 'circle'),
          _buildToolButton(Icons.text_fields, 'text'),
          _buildToolButton(Icons.image, 'image'),
          if (_selectedTool != 'select' && _selectedTool != 'image') ...[
            _buildColorButton('Stroke', _selectedColor, (color) {
              setState(() => _selectedColor = color);
            }),
            if (_selectedTool != 'pen') 
              _buildColorButton('Fill', _selectedFillColor, (color) {
                setState(() => _selectedFillColor = color);
              }),
            _buildStrokeWidthSlider(),
          ],
          if (_selectedElement != null) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedElement,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _selectedTool == tool ? Colors.blue : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        color: _selectedTool == tool ? Colors.white : Colors.black,
        onPressed: () {
          setState(() => _selectedTool = tool);
          if (tool == 'text') {
            _addText();
          } else if (tool == 'image') {
            _pickImage();
          }
        },
      ),
    );
  }

  Widget _buildColorButton(String label, Color color, ValueChanged<Color> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          IconButton(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey),
                shape: BoxShape.circle,
              ),
            ),
            onPressed: () async {
              final newColor = await showColorPicker(context, color);
              if (newColor != null) {
                onChanged(newColor);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Slider(
          value: _strokeWidth,
          min: 1,
          max: 20,
          onChanged: (value) {
            setState(() => _strokeWidth = value);
          },
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final pos = _transformationController.toScene(details.localPosition);
    setState(() {
      if (_selectedTool == 'pen') {
        _currentPath = PathElement(
          position: pos,
          color: _selectedColor,
          strokeWidth: _strokeWidth,
        );
        _elements.add(_currentPath!);
      } else if (_selectedTool == 'select') {
        _selectedElement = _hitTest(pos);
        if (_selectedElement != null) {
          _isResizing = _getResizeHandle(pos) != null;
          _activeHandle = _getResizeHandle(pos);
          _startPoint = pos;
        }
      } else if (_selectedTool == 'rectangle' || _selectedTool == 'circle') {
        _startPoint = pos;
        _currentShape = ShapeElement(
          position: pos,
          type: _selectedTool == 'rectangle' ? ShapeType.rectangle : ShapeType.circle,
          size: Size.zero,
          fillColor: _selectedFillColor,
          strokeColor: _selectedColor,
          strokeWidth: _strokeWidth,
        );
        _elements.add(_currentShape!);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = _transformationController.toScene(details.localPosition);
    setState(() {
      if (_selectedTool == 'pen' && _currentPath != null) {
        _currentPath!.addPoint(pos);
      } else if (_selectedTool == 'select' && _selectedElement != null) {
        if (_isResizing && _startPoint != null) {
          _handleResize(pos);
        } else {
          final delta = details.delta / _canvasScale;
          _selectedElement!.position += delta;
        }
      } else if ((_selectedTool == 'rectangle' || _selectedTool == 'circle') && 
                 _currentShape != null && _startPoint != null) {
        final newSize = Offset(
          (pos.dx - _startPoint!.dx).abs(),
          (pos.dy - _startPoint!.dy).abs(),
        );
        _currentShape!.position = Offset(
          min(_startPoint!.dx, pos.dx),
          min(_startPoint!.dy, pos.dy),
        );
        _currentShape!.resize(newSize);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _currentPath = null;
      _currentShape = null;
      _startPoint = null;
      _isResizing = false;
      _activeHandle = null;
    });
  }

  CanvasElement? _hitTest(Offset position) {
    for (var element in _elements.reversed) {
      if (element.hitTest(position)) {
        return element;
      }
    }
    return null;
  }

  void _addText() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        double fontSize = 24;
        Color textColor = _selectedColor;
        Color backgroundColor = _selectedFillColor;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add/Edit Text'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Text'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Font Size:'),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 8,
                          max: 72,
                          onChanged: (value) {
                            setState(() => fontSize = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Text Color'),
                          InkWell(
                            onTap: () async {
                              final color = await showColorPicker(context, textColor);
                              if (color != null) {
                                setState(() => textColor = color);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: textColor,
                                border: Border.all(),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Background'),
                          InkWell(
                            onTap: () async {
                              final color = await showColorPicker(context, backgroundColor);
                              if (color != null) {
                                setState(() => backgroundColor = color);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: Border.all(),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      setState(() {
                        _elements.add(TextElement(
                          text: textController.text,
                          position: Offset(
                            widget.canvasWidth / 2,
                            widget.canvasHeight / 2,
                          ),
                          style: TextStyle(
                            fontSize: fontSize,
                            color: textColor,
                            backgroundColor: backgroundColor,
                          ),
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageData = await image.readAsBytes();
      final uiImage = await decodeImageFromList(imageData);
      setState(() {
        _elements.add(ImageElement(
          image: uiImage,
          position: Offset(
            widget.canvasWidth / 2 - uiImage.width / 2,
            widget.canvasHeight / 2 - uiImage.height / 2,
          ),
        ));
      });
    }
  }

  void _showLayersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Layers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ReorderableListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < _elements.length; i++)
                ListTile(
                  key: ValueKey(i),
                  title: Text(_elements[i].toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _elements.removeAt(i);
                      });
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    setState(() => _selectedElement = _elements[i]);
                    Navigator.pop(context);
                  },
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _elements.removeAt(oldIndex);
                _elements.insert(newIndex, item);
              });
            },
          ),
        ),
      ),
    );
  }

  Future<void> _exportCanvas() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, widget.canvasWidth, widget.canvasHeight),
      );

      final painter = CanvasPainter(
        elements: _elements,
        selectedElement: null,
      );
      painter.paint(canvas, Size(widget.canvasWidth, widget.canvasHeight));

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        widget.canvasWidth.round(),
        widget.canvasHeight.round(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'canvas_export_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }

  void _deleteSelectedElement() {
    if (_selectedElement != null) {
      setState(() {
        _elements.remove(_selectedElement);
        _selectedElement = null;
      });
    }
  }

  void _showColorPicker() async {
    final Color? color = await showColorPicker(context, _selectedColor);
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  Future<Color?> showColorPicker(BuildContext context, Color initialColor) async {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (color) => initialColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, initialColor),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  ResizeHandle? _getResizeHandle(Offset point) {
    if (_selectedElement == null) return null;
    
    // Implementation for resize handles...
    // Add logic to detect which handle was clicked
    return null;
  }

  void _handleResize(Offset point) {
    if (_selectedElement == null || _startPoint == null || _activeHandle == null) return;

    if (_selectedElement is ImageElement) {
      final image = _selectedElement as ImageElement;
      final newSize = _calculateNewSize(point);
      image.resize(newSize, fromCenter: _activeHandle == ResizeHandle.center);
    } else if (_selectedElement is ShapeElement) {
      final shape = _selectedElement as ShapeElement;
      final newSize = _calculateNewSize(point);
      shape.resize(newSize, fromCenter: _activeHandle == ResizeHandle.center);
    }
  }

  Offset _calculateNewSize(Offset point) {
    // Implementation for calculating new size based on resize handle...
    return Offset.zero;
  }
}

enum ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
} 