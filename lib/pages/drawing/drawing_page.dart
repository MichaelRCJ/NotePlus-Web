import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class DrawingPage extends StatefulWidget {
  final String? initialDrawing;

  const DrawingPage({super.key, this.initialDrawing});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late SignatureController _controller;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  Uint8List? _currentDrawingBytes;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _currentColor,
      exportBackgroundColor: Colors.white,
    );
    
    // Load initial drawing if provided
    if (widget.initialDrawing != null && widget.initialDrawing!.isNotEmpty) {
      _loadInitialDrawing();
    }
  }

  Future<void> _loadInitialDrawing() async {
    try {
      if (widget.initialDrawing!.startsWith('data:image')) {
        final base64String = widget.initialDrawing!.split(',')[1];
        final bytes = base64Decode(base64String);
        _currentDrawingBytes = bytes;
        // Note: The signature package doesn't support loading from bytes
        // The user will need to redraw or we can show the image as background
      }
    } catch (e) {
      debugPrint('Error loading initial drawing: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearDrawing() {
    _controller.clear();
    _currentDrawingBytes = null;
  }

  Future<void> _saveDrawing() async {
    if (_controller.isEmpty && _currentDrawingBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay dibujo para guardar')),
      );
      return;
    }

    try {
      Uint8List? finalBytes;
      
      if (!_controller.isEmpty) {
        finalBytes = await _controller.toPngBytes();
      } else if (_currentDrawingBytes != null) {
        finalBytes = _currentDrawingBytes;
      }
      
      if (finalBytes != null) {
        // Convert bytes to base64 string for storage
        final drawingData = 'data:image/png;base64,${base64Encode(finalBytes)}';
        Navigator.of(context).pop(drawingData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<void> _changeColor(Color color) async {
    // Save current drawing before changing color
    Uint8List? savedBytes;
    if (!_controller.isEmpty) {
      savedBytes = await _controller.toPngBytes();
    }
    
    setState(() {
      _currentColor = color;
      // Create a new controller with the new color
      _controller.dispose();
      _controller = SignatureController(
        penStrokeWidth: _strokeWidth,
        penColor: color,
        exportBackgroundColor: Colors.white,
      );
      // Store the saved bytes to restore later if needed
      if (savedBytes != null) {
        _currentDrawingBytes = savedBytes;
      }
    });
  }

  Future<void> _changeStrokeWidth(double width) async {
    // Save current drawing before changing stroke width
    Uint8List? savedBytes;
    if (!_controller.isEmpty) {
      savedBytes = await _controller.toPngBytes();
    }
    
    setState(() {
      _strokeWidth = width;
      // Create a new controller with the new stroke width
      final currentColor = _currentColor;
      _controller.dispose();
      _controller = SignatureController(
        penStrokeWidth: width,
        penColor: currentColor,
        exportBackgroundColor: Colors.white,
      );
      // Store the saved bytes
      if (savedBytes != null) {
        _currentDrawingBytes = savedBytes;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dibujo / Escritura a mano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearDrawing,
            tooltip: 'Limpiar',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Color picker
                const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ..._getColorOptions().map((color) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _changeColor(color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _currentColor == color ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _currentColor == color
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                    )),
                const Spacer(),
                // Stroke width
                const Text('Grosor:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: _strokeWidth,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: _strokeWidth.toStringAsFixed(0),
                    onChanged: _changeStrokeWidth,
                  ),
                ),
              ],
            ),
          ),
          // Drawing area
          Expanded(
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Show previous drawing as background if exists
                  if (_currentDrawingBytes != null)
                    Positioned.fill(
                      child: Image.memory(
                        _currentDrawingBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  // Signature pad on top
                  Signature(
                    controller: _controller,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getColorOptions() {
    return [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.pink,
    ];
  }
}
