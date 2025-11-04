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
        // Mulai dari LOW dulu; kalau sudah jalan baru naikkan.
        ResolutionPreset.low,
        enableAudio: false,                    // hindari izin mic
        imageFormatGroup: ImageFormatGroup.bgra8888, // aman untuk web
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Camera Web Test')),
        body: Center(
          child: _err != null
              ? Text(_err!)
              : (_controller == null || !_controller!.value.isInitialized)
                  ? const CircularProgressIndicator()
                  : SizedBox(                     // beri ukuran eksplisit biar <video> tidak 0x0
                      width: 640,
                      height: 480,
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    ),
        ),
      ),
    );
  }
}
