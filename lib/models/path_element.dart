import 'package:flutter/material.dart';
import 'canvas_element.dart';

class PathElement extends CanvasElement {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  Path? _cachedPath;

  PathElement({
    required Offset position,
    required this.color,
    required this.strokeWidth,
  }) : points = [position],
       super(position: position);

  void addPoint(Offset point) {
    points.add(point);
    _cachedPath = null;  // Invalidate cache
  }

  Path _buildPath() {
    if (_cachedPath != null) return _cachedPath!;
    
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);
    if (points.length < 3) {
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    } else {
      // Use quadratic bezier curves for smoother lines
      for (var i = 1; i < points.length - 1; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final p2 = points[i + 1];
        
        final controlPoint = p1;
        final endPoint = Offset(
          (p1.dx + p2.dx) / 2,
          (p1.dy + p2.dy) / 2,
        );
        
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          endPoint.dx,
          endPoint.dy,
        );
      }
    }

    _cachedPath = path;
    return path;
  }

  @override
  bool hitTest(Offset point) {
    const hitTestThreshold = 10.0;
    final path = _buildPath();
    return path.contains(point) || 
           (PathMetrics.fromPath(path)
               .any((metric) => metric.getTangentForOffset(metric.length)?.position
               .distanceTo(point) ?? double.infinity < hitTestThreshold));
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(_buildPath(), paint);
  }

  @override
  String toString() => 'Path';
} 