import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:flutter/material.dart';
import '../models/canvas_element.dart';
import '../models/shape_element.dart';
import '../models/path_element.dart';

class CanvasPainter extends CustomPainter {
  final List<CanvasElement> elements;
  final CanvasElement? selectedElement;
  final bool showHandles;

  CanvasPainter({
    required this.elements,
    this.selectedElement,
    this.showHandles = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      element.render(canvas);
      if (element == selectedElement && showHandles) {
        _drawSelectionBox(canvas, element);
      }
    }
  }

  void _drawSelectionBox(Canvas canvas, CanvasElement element) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Size elementSize;
    if (element is ShapeElement) {
      elementSize = element.size;
    } else if (element is ImageElement) {
      elementSize = element.size;
    } else if (element is TextElement) {
      final textPainter = TextPainter(
        text: TextSpan(text: element.text, style: element.style),
        textDirection: TextDirection.ltr,
      )..layout();
      elementSize = textPainter.size;
    } else if (element is PathElement) {
      // For path elements, calculate bounding box
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final point in element.points) {
        minX = min(minX, point.dx);
        minY = min(minY, point.dy);
        maxX = max(maxX, point.dx);
        maxY = max(maxY, point.dy);
      }

      element.position = Offset(minX, minY);
      elementSize = Size(maxX - minX, maxY - minY);
    } else {
      return;
    }

    final rect = Rect.fromLTWH(
      element.position.dx - 4,
      element.position.dy - 4,
      elementSize.width + 8,
      elementSize.height + 8,
    );

    // Draw selection rectangle
    canvas.drawRect(rect, paint);

    // Draw resize handles
    _drawResizeHandle(canvas, rect.topLeft);
    _drawResizeHandle(canvas, rect.topRight);
    _drawResizeHandle(canvas, rect.bottomLeft);
    _drawResizeHandle(canvas, rect.bottomRight);
    _drawResizeHandle(canvas, rect.center);
  }

  void _drawResizeHandle(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(position, 6, paint);
    canvas.drawCircle(position, 6, borderPaint);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      elements != oldDelegate.elements ||
      selectedElement != oldDelegate.selectedElement ||
      showHandles != oldDelegate.showHandles;
} 