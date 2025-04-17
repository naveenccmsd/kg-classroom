import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeworkViewer extends StatefulWidget {
  final String homeworkId;
  final String studentEmail;

  const HomeworkViewer({
    required this.homeworkId,
    required this.studentEmail,
    Key? key,
  }) : super(key: key);

  @override
  _HomeworkViewerState createState() => _HomeworkViewerState();
}

class _HomeworkViewerState extends State<HomeworkViewer> {
  int _currentIndex = 0;
  late ui.Image _image;
  bool _isImageLoaded = false;
  List<String> _imageNames = [];
  List<Offset> _points = [];
  bool _isSaving = false;
  String _selectedTool = 'Pen'; // Default tool

  @override
  void initState() {
    super.initState();
    _fetchImageNames();
  }

  Future<void> _fetchImageNames() async {
    try {
      final studentImagesCollection = FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentEmail)
          .collection('assignedHomeworks')
          .doc(widget.homeworkId)
          .collection('images');

      final imagesSnapshot = await studentImagesCollection.get();
      if (imagesSnapshot.docs.isEmpty) {
        // Fetch images from the teacher's original homework collection
        final teacherImagesCollection = FirebaseFirestore.instance
            .collection('homeworks')
            .doc(widget.homeworkId)
            .collection('images');

        final teacherImagesSnapshot = await teacherImagesCollection.get();

        for (var doc in teacherImagesSnapshot.docs) {
          final data = doc.data();
          await studentImagesCollection.doc(doc.id).set({
            'name': data['name'],
            'data': data['data'],
          });
        }

        // Re-fetch the student images after copying
        final updatedSnapshot = await studentImagesCollection.get();
        setState(() {
          _imageNames = _sortImageNamesByNumber(updatedSnapshot.docs.map((doc) => doc.id).toList());
        });
      } else {
        setState(() {
          _imageNames = _sortImageNamesByNumber(imagesSnapshot.docs.map((doc) => doc.id).toList());
        });
      }

      if (_imageNames.isNotEmpty) {
        _fetchAndLoadImage(_imageNames[_currentIndex]);
      }
    } catch (e) {
      debugPrint('Error fetching image names: $e');
    }
  }
  List<String> _sortImageNamesByNumber(List<String> imageNames) {
    final regex = RegExp(r'\d+'); // Regular expression to extract numbers
    imageNames.sort((a, b) {
      final aNumber = int.tryParse(regex.firstMatch(a)?.group(0) ?? '0') ?? 0;
      final bNumber = int.tryParse(regex.firstMatch(b)?.group(0) ?? '0') ?? 0;
      return aNumber.compareTo(bNumber);
    });
    return imageNames;
  }

  Future<void> _fetchAndLoadImage(String imageName) async {
    try {
      final imageDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentEmail)
          .collection('assignedHomeworks')
          .doc(widget.homeworkId)
          .collection('images')
          .doc(imageName)
          .get();

      if (imageDoc.exists) {
        final imageData = imageDoc.data()?['data'];
        if (imageData != null) {
          final decodedData = base64Decode(imageData);
          final ui.Codec codec = await ui.instantiateImageCodec(decodedData);
          final ui.FrameInfo frame = await codec.getNextFrame();
          setState(() {
            _image = frame.image;
            _isImageLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching or loading image: $e');
    }
  }


  Future<void> _clearImage() async {
    try {
      final teacherImageDoc = await FirebaseFirestore.instance
          .collection('homeworks')
          .doc(widget.homeworkId)
          .collection('images')
          .doc(_imageNames[_currentIndex])
          .get();

      if (teacherImageDoc.exists) {
        final imageData = teacherImageDoc.data()?['data'];
        if (imageData != null) {
          final decodedData = base64Decode(imageData);
          final ui.Codec codec = await ui.instantiateImageCodec(decodedData);
          final ui.FrameInfo frame = await codec.getNextFrame();
          setState(() {
            _image = frame.image;
            _isImageLoaded = true;
            _points.clear(); // Clear any edits
          });

          // Replace the current image in the student's collection
          await FirebaseFirestore.instance
              .collection('students')
              .doc(widget.studentEmail)
              .collection('assignedHomeworks')
              .doc(widget.homeworkId)
              .collection('images')
              .doc(_imageNames[_currentIndex])
              .update({'data': imageData});
        }
      }
    } catch (e) {
      debugPrint('Error clearing image: $e');
    }
  }

  Future<void> _saveEdits(String imageName) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(_image, Offset.zero, Paint());

      final paint = Paint()
        ..color = Colors.blue
        ..strokeWidth = _selectedTool == 'Pen' ? 3.0 : 8.0
        ..strokeCap = _selectedTool == 'Pen' ? StrokeCap.round : StrokeCap.square;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != Offset.zero && _points[i + 1] != Offset.zero) {
          canvas.drawLine(_points[i], _points[i + 1], paint);
        }
      }

      final picture = recorder.endRecording();
      final editedImage = await picture.toImage(_image.width, _image.height);
      final byteData = await editedImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List imageBytes = byteData!.buffer.asUint8List();

      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentEmail)
          .collection('assignedHomeworks')
          .doc(widget.homeworkId)
          .collection('images')
          .doc(imageName)
          .update({'data': base64Encode(imageBytes)});
    } catch (e) {
      debugPrint('Error saving edits: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _navigateToImage(int newIndex) async {
    if (_isSaving) return;
    await _saveEdits(_imageNames[_currentIndex]);
    setState(() {
      _currentIndex = newIndex;
      _isImageLoaded = false;
      _points.clear();
    });
    _fetchAndLoadImage(_imageNames[newIndex]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Viewer'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Clear Canvas') {
                setState(() {
                  _points.clear();
                });
              } else if (value == 'Clear Image') {
                await _clearImage();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Clear Canvas', child: Text('Clear Canvas')),
              const PopupMenuItem(value: 'Clear Image', child: Text('Clear Image')),
              const PopupMenuItem(value: 'Pen', child: Text('Pen')),
              const PopupMenuItem(value: 'Brush', child: Text('Brush')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Center(
        child: _isImageLoaded
            ? LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / _image.width;
            final scaleY = constraints.maxHeight / _image.height;
            final scale = scaleX < scaleY ? scaleX : scaleY;

            return GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final localPosition = details.localPosition;
                  final scaledPosition = Offset(
                    localPosition.dx / scale,
                    localPosition.dy / scale,
                  );
                  _points.add(scaledPosition);
                });
              },
              onPanEnd: (details) {
                _points.add(Offset.zero);
              },
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _image.width.toDouble(),
                  height: _image.height.toDouble(),
                  child: CustomPaint(
                    painter: ImagePainter(_image, _points, _selectedTool),
                  ),
                ),
              ),
            );
          },
        )
            : const CircularProgressIndicator(),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentIndex > 0 ? () => _navigateToImage(_currentIndex - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentIndex < _imageNames.length - 1
                ? () => _navigateToImage(_currentIndex + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> points;
  final String tool;

  ImagePainter(this.image, this.points, this.tool);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = tool == 'Pen' ? 3.0 : 8.0
      ..strokeCap = tool == 'Pen' ? StrokeCap.round : StrokeCap.square;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}