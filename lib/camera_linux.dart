import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'camera_linux_bindings_generated.dart';

class CameraLinux {
  late CameraLinuxBindings _bindings;

  CameraLinux() {
    final dylib = DynamicLibrary.open('libcamera_linux.so');
    _bindings = CameraLinuxBindings(dylib);
  }

  // Open Default Camera
  Future<void> initializeCamera() async {
    _bindings.startVideoCaptureInThread();
  }

  // Close The Camera
  void stopCamera() {
    _bindings.stopVideoCapture();
  }

  // Convert Frame Into Base64
  String _uint8ListToBase64Url(Uint8List data) {
    String base64String = base64Encode(data);

    String base64Url = base64String
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');

    int requiredLength = (4 - (base64Url.length % 4)) % 4;
    return base64Url + '=' * requiredLength;
  }

  // Capture The Frame
  Future<String> captureImage() async {
    final lengthPtr = calloc<Int>();
    Pointer<Uint8>? latestFramePtr;
    try {
      latestFramePtr = _bindings.getLatestFrameBytes(lengthPtr);
      final latestFrame = _getLatestFrameData(latestFramePtr, lengthPtr.value);
      final base64Image = _uint8ListToBase64Url(latestFrame);
      return base64Image;
    } catch (_) {
      rethrow;
    } finally {
      calloc.free(lengthPtr);
      if (latestFramePtr != null) {
        calloc.free(latestFramePtr);
      }
    }
  }

  // Get The Latest Frame
  Uint8List _getLatestFrameData(Pointer<Uint8> framePointer, frameSize) {
    List<int> frameList = framePointer.asTypedList(frameSize);
    return Uint8List.fromList(frameList);
  }
}
