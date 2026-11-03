import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/bindings.dart' as bindings;

/// A V4L2 video capture device this package can stream from.
class CameraLinuxDevice {
  const CameraLinuxDevice({
    required this.path,
    required this.name,
    required this.pixelFormat,
  });

  /// Device node, such as `/dev/video0`.
  final String path;

  /// The driver's card name, such as `Depstech webcam`.
  final String name;

  /// FourCC of the pixel format that would be used, such as `YUYV` or `MJPG`.
  final String pixelFormat;

  @override
  String toString() => '$path ($name, $pixelFormat)';
}

/// Thrown when the native side reports a failure.
class CameraLinuxException implements Exception {
  const CameraLinuxException(this.message);

  final String message;

  @override
  String toString() => 'CameraLinuxException: $message';
}

/// Captures frames from a webcam on Linux.
///
/// Only one capture runs at a time per process: starting a second
/// [CameraLinux] stops the first.
class CameraLinux {
  CameraLinux();

  /// Lists the devices [initializeCamera] can open, in the order it would
  /// try them.
  static List<CameraLinuxDevice> availableDevices() {
    _checkPlatform();
    final ptr = bindings.cameraLinuxListDevices();
    if (ptr == nullptr) return const [];
    try {
      final text = ptr.toDartString();
      return [
        for (final line in const LineSplitter().convert(text))
          if (line.split('\t') case [final path, final name, final fourcc])
            CameraLinuxDevice(path: path, name: name, pixelFormat: fourcc),
      ];
    } finally {
      bindings.cameraLinuxFree(ptr.cast());
    }
  }

  /// Opens the camera and starts capturing in a background thread.
  ///
  /// [devicePath] selects a device node; when null the `CAMERA_LINUX_DEVICE`
  /// environment variable is used, and otherwise the first device from
  /// [availableDevices]. [width] and [height] are a request that the driver
  /// may adjust; see [frameSize]. Throws a [CameraLinuxException] when no
  /// camera can be opened.
  Future<void> initializeCamera({
    String? devicePath,
    int width = 640,
    int height = 480,
    int jpegQuality = 85,
  }) async {
    _checkPlatform();
    final device = devicePath == null ? nullptr : devicePath.toNativeUtf8();
    try {
      final rc = bindings.cameraLinuxStart(device, width, height, jpegQuality);
      if (rc != 0) {
        throw CameraLinuxException(_lastError() ?? 'failed to open camera');
      }
    } finally {
      if (device != nullptr) calloc.free(device);
    }
  }

  /// Stops capturing and releases the device.
  void stopCamera() {
    if (!Platform.isLinux) return;
    bindings.cameraLinuxStop();
  }

  /// Whether frames are being captured.
  bool get isRunning =>
      Platform.isLinux &&
      bindings.cameraLinuxStatus() == bindings.cameraLinuxRunning;

  /// The negotiated frame size, or null when the camera is not open.
  ({int width, int height})? get frameSize {
    if (!Platform.isLinux) return null;
    final w = calloc<Int32>();
    final h = calloc<Int32>();
    try {
      if (bindings.cameraLinuxFrameSize(w, h) != 0) return null;
      return (width: w.value, height: h.value);
    } finally {
      calloc.free(w);
      calloc.free(h);
    }
  }

  /// Path of the device in use, or null when the camera is not open.
  String? get devicePath {
    if (!Platform.isLinux) return null;
    final ptr = bindings.cameraLinuxDevice();
    if (ptr == nullptr) return null;
    try {
      return ptr.toDartString();
    } finally {
      bindings.cameraLinuxFree(ptr.cast());
    }
  }

  /// Returns the newest frame as JPEG bytes, or null when no frame has
  /// arrived since the previous call.
  ///
  /// Throws a [CameraLinuxException] when the capture has stopped because of
  /// an error, such as the camera being unplugged.
  Uint8List? captureJpeg() {
    _checkPlatform();
    final length = calloc<Int32>();
    try {
      final ptr = bindings.cameraLinuxReadJpeg(length);
      if (ptr == nullptr) {
        if (bindings.cameraLinuxStatus() == bindings.cameraLinuxFailed) {
          throw CameraLinuxException(_lastError() ?? 'capture stopped');
        }
        return null;
      }
      try {
        return Uint8List.fromList(ptr.asTypedList(length.value));
      } finally {
        bindings.cameraLinuxFree(ptr.cast());
      }
    } finally {
      calloc.free(length);
    }
  }

  /// Returns the newest frame as a base64url-encoded JPEG, or an empty string
  /// when no new frame is available yet.
  ///
  /// Kept for compatibility with earlier versions; [captureJpeg] avoids the
  /// base64 round trip.
  Future<String> captureImage() async {
    final jpeg = captureJpeg();
    if (jpeg == null) return '';
    return base64Url.encode(jpeg);
  }

  static String? _lastError() {
    final ptr = bindings.cameraLinuxLastError();
    if (ptr == nullptr) return null;
    try {
      return ptr.toDartString();
    } finally {
      bindings.cameraLinuxFree(ptr.cast());
    }
  }

  static void _checkPlatform() {
    if (!Platform.isLinux) {
      throw UnsupportedError('camera_linux only works on Linux');
    }
  }
}
