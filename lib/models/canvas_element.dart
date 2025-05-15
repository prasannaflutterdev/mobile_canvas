import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math';


abstract class CanvasElement {
  Offset position;
  CanvasElement({required this.position});

  bool hitTest(Offset point);
  void render(Canvas canvas);
  String toString();
}

class LineElement extends CanvasElement {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  LineElement({
    required this.start,
    required this.end,
    required this.color,
    required this.strokeWidth,
  }) : super(position: start);

  @override
  bool hitTest(Offset point) {
    const hitTestThreshold = 10.0;
    final distanceToLine = _distanceToLine(point, start, end);
    return distanceToLine < hitTestThreshold;
  }

  double _distanceToLine(Offset point, Offset start, Offset end) {
    final numerator = ((end.dy - start.dy) * point.dx -
            (end.dx - start.dx) * point.dy +
            end.dx * start.dy -
            end.dy * start.dx)
        .abs();
    final denominator = sqrt((end.dx - start.dx) * (end.dx - start.dx) +
            (end.dy - start.dy) * (end.dy - start.dy));
    return numerator / denominator;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  @override
  String toString() => 'Line';
}

class TextElement extends CanvasElement {
  String text;
  TextStyle style;

  TextElement({
    required this.text,
    required Offset position,
    required this.style,
  }) : super(position: position);

  @override
  bool hitTest(Offset point) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final size = textPainter.size;
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );
    return rect.contains(point);
  }

  @override
  void render(Canvas canvas) {
    if (style.backgroundColor != null && style.backgroundColor != Colors.transparent) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final backgroundPaint = Paint()..color = style.backgroundColor!;
      canvas.drawRect(
        Rect.fromLTWH(
          position.dx,
          position.dy,
          textPainter.width,
          textPainter.height,
        ),
        backgroundPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position);
  }

  @override
  String toString() => 'Text: $text';
}

class ImageElement extends CanvasElement {
  final ui.Image image;
  Size size;
  double rotation = 0.0;
  bool maintainAspectRatio = true;
  Rect? cropRect;

  ImageElement({
    required this.image,
    required Offset position,
  }) : size = Size(image.width.toDouble(), image.height.toDouble()),
       super(position: position);

  @override
  bool hitTest(Offset point) {
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    return rect.contains(point);
  }

  void resize(Offset newSize, {bool fromCenter = false}) {
    if (maintainAspectRatio) {
      final aspectRatio = image.width / image.height;
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
    
    // Update crop rect if it exists
    if (cropRect != null) {
      final scaleX = size.width / image.width;
      final scaleY = size.height / image.height;
      cropRect = Rect.fromLTWH(
        cropRect!.left * scaleX,
        cropRect!.top * scaleY,
        cropRect!.width * scaleX,
        cropRect!.height * scaleY,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = cropRect ?? Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    
    canvas.drawImageRect(image, src, rect, Paint());
    canvas.restore();
  }

  @override
  String toString() => 'Image';
} 