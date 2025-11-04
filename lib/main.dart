import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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

  
  final Color _seedColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    _init();
  }

  
  Future<void> _init() async {
    try {
      final cam = _cameras.first;
      _controller = CameraController(
        cam,
        ResolutionPreset.low, 
        enableAudio: false, 
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } on CameraException catch (e) {
      setState(() => _err = 'CameraException ${e.code}: ${e.description}');
    } catch (e) {
      setState(() => _err = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
        ),
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera M3 Demo',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Material 3 + Camera Demo')),
        floatingActionButton: FilledButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Capture'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tombol Capture ditekan')),
            );
          },
        ),
        body: Center(
          child: _err != null
              ? Text(_err!)
              : (_controller == null || !_controller!.value.isInitialized)
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(
                              width: 640,
                              height: 480,
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: () {},
                              child: const Text('Save Photo'),
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Gallery'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.settings),
                              label: const Text('Settings'),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
