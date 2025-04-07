import 'package:flutter/material.dart';

class DrawCanvasPage extends StatefulWidget {
  final String imageUrl;
  final bool isTeacher;

  const DrawCanvasPage({required this.imageUrl, required this.isTeacher, Key? key}) : super(key: key);

  @override
  _DrawCanvasPageState createState() => _DrawCanvasPageState();
}

class _DrawCanvasPageState extends State<DrawCanvasPage> {
  List<Offset> points = [];
  bool isEraser = false;

  void _clearCanvas() {
    setState(() {
      points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw Canvas')),
      body: Stack(
        children: [
          Center(
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                points.add(renderBox.globalToLocal(details.localPosition));
              });
            },
            onPanEnd: (details) {
              points.add(Offset.zero);
            },
            child: CustomPaint(
              painter: _DrawPainter(points: points, isEraser: isEraser),
              size: Size.infinite,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      isEraser = !isEraser;
                    });
                  },
                  child: Icon(isEraser ? Icons.brush : Icons.create),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _clearCanvas,
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawPainter extends CustomPainter {
  final List<Offset> points;
  final bool isEraser;

  _DrawPainter({required this.points, required this.isEraser});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = isEraser ? Colors.transparent : Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}