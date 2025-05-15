import 'package:flutter/material.dart';
import 'canvas_element.dart';

enum ShapeType { rectangle, circle }

class ShapeElement extends CanvasElement {
  ShapeType type;
  Size size;
  Color fillColor;
  Color strokeColor;
  double strokeWidth;
  bool maintainAspectRatio;

  ShapeElement({
    required Offset position,
    required this.type,
    required this.size,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.0,
    this.maintainAspectRatio = false,
  }) : super(position: position);

  @override
  bool hitTest(Offset point) {
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    if (type == ShapeType.rectangle) {
      return rect.contains(point);
    } else if (type == ShapeType.circle) {
      final center = Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
      final radius = size.width / 2;
      return (point - center).distance <= radius;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (type == ShapeType.rectangle) {
      final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, strokePaint);
    } else if (type == ShapeType.circle) {
      final center = Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
      final radius = size.width / 2;
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  void resize(Offset newSize, {bool fromCenter = false}) {
    if (maintainAspectRatio) {
      final aspectRatio = size.width / size.height;
      if (newSize.dx / newSize.dy > aspectRatio) {
        newSize = Offset(newSize.dy * aspectRatio, newSize.dy);
      } else {
        newSize = Offset(newSize.dx, newSize.dx / aspectRatio);
      }
    }

    if (fromCenter) {
      position = Offset(
        position.dx - (newSize.dx - size.width) / 2,
        position.dy - (newSize.dy - size.height) / 2,
      );
    }

    size = Size(newSize.dx, newSize.dy);
  }

  @override
  String toString() => '${type.toString().split('.').last} Shape';
} 