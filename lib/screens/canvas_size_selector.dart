import 'package:flutter/material.dart';
import 'canvas_editor.dart';

class CanvasSizeSelector extends StatelessWidget {
  const CanvasSizeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Canvas Size'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _sizeCard(context, 'Instagram Post', 1080, 1080),
          _sizeCard(context, 'Instagram Story', 1080, 1920),
          _sizeCard(context, 'Facebook Post', 1200, 630),
          _sizeCard(context, 'Twitter Post', 1200, 675),
          _sizeCard(context, 'Custom Size', null, null),
        ],
      ),
    );
  }

  Widget _sizeCard(BuildContext context, String title, int? width, int? height) {
    return Card(
      child: InkWell(
        onTap: () {
          if (width != null && height != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CanvasEditorScreen(
                  canvasWidth: width.toDouble(),
                  canvasHeight: height.toDouble(),
                ),
              ),
            );
          } else {
            _showCustomSizeDialog(context);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (width != null && height != null)
              Text(
                '${width}x$height',
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _showCustomSizeDialog(BuildContext context) {
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Custom Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              decoration: const InputDecoration(labelText: 'Width (px)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(labelText: 'Height (px)'),
              keyboardType: TextInputType.number,
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
              final width = double.tryParse(widthController.text);
              final height = double.tryParse(heightController.text);
              if (width != null && height != null) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CanvasEditorScreen(
                      canvasWidth: width,
                      canvasHeight: height,
                    ),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
} 