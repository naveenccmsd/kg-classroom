import 'package:flutter/material.dart';

class DrawCanvasPage extends StatefulWidget {
  final String imageUrl;
  final bool isTeacher;
  final String studentName;

  const DrawCanvasPage({required this.imageUrl, required this.isTeacher, required this.studentName, Key? key}) : super(key: key);

  @override
  _DrawCanvasPageState createState() => _DrawCanvasPageState();
}

class _DrawCanvasPageState extends State<DrawCanvasPage> {
  List<Offset> points = [];
  bool isEraser = false;
  double imageWidth = 0.0;
  double imageHeight = 0.0;
  final GlobalKey _imageKey = GlobalKey();

  void _clearCanvas() {
    setState(() {
      points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Canvas'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Stack(
                children: [
                  Center(
                    child: Image.network(
                      widget.imageUrl,
                      key: _imageKey,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                            if (renderBox != null && imageWidth == 0.0 && imageHeight == 0.0) {
                              setState(() {
                                imageWidth = renderBox.size.width;
                                imageHeight = renderBox.size.height;
                              });
                            }
                          });
                          return child;
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                  if (imageWidth > 0 && imageHeight > 0)
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            final localPosition = renderBox.globalToLocal(details.globalPosition);
                            if (localPosition.dx >= 0 &&
                                localPosition.dy >= 0 &&
                                localPosition.dx <= imageWidth &&
                                localPosition.dy <= imageHeight) {
                              points.add(Offset(
                                localPosition.dx / imageWidth,
                                localPosition.dy / imageHeight,
                              ));
                            }
                          }
                        });
                      },
                      onPanEnd: (details) {
                        points.add(Offset.zero);
                      },
                      child: SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: CustomPaint(
                          painter: _DrawPainter(points: points, imageWidth: imageWidth, imageHeight: imageHeight),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'paint',
            onPressed: () {
              setState(() {
                isEraser = !isEraser;
              });
            },
            child: Icon(isEraser ? Icons.brush : Icons.create),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'eraser',
            onPressed: _clearCanvas,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}

class _DrawPainter extends CustomPainter {
  final List<Offset> points;
  final double imageWidth;
  final double imageHeight;

  _DrawPainter({required this.points, required this.imageWidth, required this.imageHeight});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        final p1 = Offset(points[i].dx * imageWidth, points[i].dy * imageHeight);
        final p2 = Offset(points[i + 1].dx * imageWidth, points[i + 1].dy * imageHeight);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}