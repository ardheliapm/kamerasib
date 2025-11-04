// ignore_for_file: avoid_print
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

// NOTE: kita import dart:html hanya untuk WEB (build ke web saja).
// Abaikan linter ini kalau kamu hanya target web.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // aman untuk web; untuk mobile abaikan atau hapus

late final List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const CameraApp());
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});
  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController? _controller;
  String? _err;
  int _selectedIndex = 0;               
  Uint8List? _lastPhotoBytes;           
  String? _lastSavedPath;               

  
  final Color _seedColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final cam = _cameras[_selectedIndex];
      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,         
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _controller?.dispose();
        _controller = ctrl;
        _err = null;
      });
    } on CameraException catch (e) {
      setState(() => _err = 'CameraException ${e.code}: ${e.description}');
    } catch (e) {
      setState(() => _err = e.toString());
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _showSnack('Tidak ada kamera lain.');
      return;
    }
    
    final current = _cameras[_selectedIndex].lensDirection;
    final targetDirection = current == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final idx = _cameras.indexWhere((c) => c.lensDirection == targetDirection);
    if (idx == -1) {
      _showSnack('Kamera $targetDirection tidak tersedia.');
      return;
    }
    setState(() => _selectedIndex = idx);
    await _controller?.dispose();
    await _initController();
  }

  Future<void> _takePhoto() async {
    if (!(_controller?.value.isInitialized ?? false)) return;
    try {
      final file = await _controller!.takePicture();

     
      final bytes = await file.readAsBytes();
      setState(() {
        _lastPhotoBytes = bytes;
      });

      
      final fileName =
          'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
       
        final blob = html.Blob([bytes], 'image/jpeg');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(url);
        _lastSavedPath = fileName; 
        _showSnack('Foto diunduh: $fileName');
      } else {
        
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$fileName';
        await file.saveTo(path);
        _lastSavedPath = path;
        _showSnack('Tersimpan: $path');
      }

      setState(() {}); // update path di UI
    } catch (e) {
      _showSnack('Gagal ambil/simpan foto: $e');
      print(e);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller?.value.isInitialized ?? false;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera M3 Demo',
      theme: _buildLightTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Material 3 + Camera'),
          actions: [
            IconButton(
              tooltip: 'Ganti kamera (depan/belakang)',
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch),
            ),
          ],
        ),
        floatingActionButton: FilledButton.icon(
          icon: const Icon(Icons.camera),
          label: const Text('Ambil Foto'),
          onPressed: initialized ? _takePhoto : null,
        ),
        body: Center(
          child: _err != null
              ? Text(_err!)
              : (!initialized)
                  ? const CircularProgressIndicator()
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Preview kamera
                          Card(
                            margin: const EdgeInsets.all(16),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: 640,
                                height: 480,
                                child: AspectRatio(
                                  aspectRatio:
                                      _controller!.value.aspectRatio,
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          
                          if (_lastSavedPath != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0),
                              child: Text(
                                kIsWeb
                                    ? 'Terunduh sebagai: $_lastSavedPath'
                                    : 'Tersimpan: $_lastSavedPath',
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 12),

                          
                          if (_lastPhotoBytes != null)
                            Column(
                              children: [
                                const Text('Preview foto terakhir'),
                                const SizedBox(height: 8),
                                Card(
                                  child: Image.memory(
                                    _lastPhotoBytes!,
                                    width: 320,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}