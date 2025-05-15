import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: _ColorPickerPainter(
              hsvColor: _hsvColor,
              onColorChanged: (color) {
                setState(() => _hsvColor = color);
                widget.onColorChanged(_hsvColor.toColor());
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Hue:'),
            Expanded(
              child: Slider(
                value: _hsvColor.hue,
                min: 0,
                max: 360,
                onChanged: (value) {
                  setState(() {
                    _hsvColor = _hsvColor.withHue(value);
                  });
                  widget.onColorChanged(_hsvColor.toColor());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorPickerPainter extends CustomPainter {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onColorChanged;

  _ColorPickerPainter({
    required this.hsvColor,
    required this.onColorChanged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint();

    // Fill the entire rect with the base color
    paint.color = Colors.white;
    canvas.drawRect(rect, paint);

    // Draw the color gradient
    for (var y = 0; y < size.height; y++) {
      for (var x = 0; x < size.width; x++) {
        final saturation = x / size.width;
        final value = 1 - (y / size.height);
        paint.color = HSVColor.fromAHSV(1, hsvColor.hue, saturation, value).toColor();
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          paint,
        );
      }
    }

    // Draw the selection indicator
    final selectedPoint = Offset(
      hsvColor.saturation * size.width,
      (1 - hsvColor.value) * size.height,
    );

    // Draw outer circle
    paint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(selectedPoint, 8, paint);

    // Draw inner circle
    paint
      ..color = HSVColor.fromAHSV(1, hsvColor.hue, hsvColor.saturation, hsvColor.value).toColor()
      ..style = PaintingStyle.fill;
    canvas.drawCircle(selectedPoint, 6, paint);
  }

  @override
  bool shouldRepaint(_ColorPickerPainter oldDelegate) =>
      hsvColor != oldDelegate.hsvColor;
} 