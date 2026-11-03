import 'dart:async';
import 'dart:typed_data';

import 'package:camera_linux/camera_linux.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _camera = CameraLinux();
  final _devices = CameraLinux.availableDevices();
  Timer? _timer;
  Uint8List? _frame;
  String _status = 'Camera stopped';

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _camera.initializeCamera();
      final size = _camera.frameSize;
      setState(() {
        _status = 'Streaming from ${_camera.devicePath} '
            'at ${size?.width}x${size?.height}';
      });
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        try {
          final frame = _camera.captureJpeg();
          if (frame != null && mounted) setState(() => _frame = frame);
        } on CameraLinuxException catch (e) {
          _stop();
          setState(() => _status = e.message);
        }
      });
    } on CameraLinuxException catch (e) {
      setState(() => _status = e.message);
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _camera.stopCamera();
    if (mounted) setState(() => _status = 'Camera stopped');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('camera_linux example')),
        body: Column(
          children: [
            Expanded(
              child: _frame == null
                  ? const Center(child: Text('No frame yet'))
                  : Image.memory(_frame!, gaplessPlayback: true),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_status),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _devices.isEmpty
                    ? 'No capture devices found'
                    : 'Devices: ${_devices.join(', ')}',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: _start, child: const Text('Start')),
                TextButton(onPressed: _stop, child: const Text('Stop')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
