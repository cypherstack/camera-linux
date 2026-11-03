// Diagnostic: lists devices, streams from the default one for a few seconds
// and writes the frames it received as JPEG files.
//
//   dart run tool/probe.dart [output_dir] [seconds]

import 'dart:io';

import 'package:camera_linux/camera_linux.dart';

void main(List<String> args) async {
  final outDir = Directory(args.isNotEmpty ? args[0] : 'probe_out')
    ..createSync(recursive: true);
  final seconds = args.length > 1 ? int.parse(args[1]) : 3;

  final devices = CameraLinux.availableDevices();
  print('devices: $devices');
  if (devices.isEmpty) {
    print('no usable device');
    exit(1);
  }

  final camera = CameraLinux();
  final sw = Stopwatch()..start();
  await camera.initializeCamera();
  print('opened ${camera.devicePath} ${camera.frameSize} '
      'in ${sw.elapsedMilliseconds} ms');

  var frames = 0, polls = 0, firstMs = -1;
  var bytes = 0;
  final readTimes = <int>[];
  while (sw.elapsedMilliseconds < 1000 + seconds * 1000) {
    final t = Stopwatch()..start();
    final jpeg = camera.captureJpeg();
    polls++;
    if (jpeg != null) {
      readTimes.add(t.elapsedMicroseconds);
      if (firstMs < 0) firstMs = sw.elapsedMilliseconds;
      frames++;
      bytes += jpeg.length;
      if (frames <= 3 || frames % 10 == 0) {
        File('${outDir.path}/frame_${frames.toString().padLeft(3, '0')}.jpg')
            .writeAsBytesSync(jpeg);
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  camera.stopCamera();
  readTimes.sort();
  print('first frame after $firstMs ms; $frames frames in $polls polls over '
      '${sw.elapsedMilliseconds} ms; '
      'avg ${frames == 0 ? 0 : bytes ~/ frames} bytes; '
      'read (convert+encode) median ${readTimes.isEmpty ? 0 : readTimes[readTimes.length ~/ 2]} us, '
      'max ${readTimes.isEmpty ? 0 : readTimes.last} us');
  print('running after stop: ${camera.isRunning}');
}
