// FFI bindings for src/camera_linux.h.
//
// The asset id of this library (package:camera_linux/src/bindings.dart) is
// what hook/build.dart registers libcamera_linux.so under, so the `@Native`
// symbols below resolve without a DynamicLibrary.open().

import 'dart:ffi';

import 'package:ffi/ffi.dart';

const int cameraLinuxStopped = 0;
const int cameraLinuxRunning = 1;
const int cameraLinuxFailed = -1;

@Native<Int32 Function(Pointer<Utf8>, Int32, Int32, Int32)>(
  symbol: 'camera_linux_start',
)
external int cameraLinuxStart(
  Pointer<Utf8> device,
  int width,
  int height,
  int jpegQuality,
);

@Native<Void Function()>(symbol: 'camera_linux_stop')
external void cameraLinuxStop();

@Native<Int32 Function()>(symbol: 'camera_linux_status')
external int cameraLinuxStatus();

@Native<Pointer<Uint8> Function(Pointer<Int32>)>(
  symbol: 'camera_linux_read_jpeg',
)
external Pointer<Uint8> cameraLinuxReadJpeg(Pointer<Int32> length);

@Native<Int32 Function(Pointer<Int32>, Pointer<Int32>)>(
  symbol: 'camera_linux_frame_size',
)
external int cameraLinuxFrameSize(Pointer<Int32> width, Pointer<Int32> height);

@Native<Pointer<Utf8> Function()>(symbol: 'camera_linux_device')
external Pointer<Utf8> cameraLinuxDevice();

@Native<Pointer<Utf8> Function()>(symbol: 'camera_linux_list_devices')
external Pointer<Utf8> cameraLinuxListDevices();

@Native<Pointer<Utf8> Function()>(symbol: 'camera_linux_last_error')
external Pointer<Utf8> cameraLinuxLastError();

@Native<Void Function(Pointer<Void>)>(symbol: 'camera_linux_free')
external void cameraLinuxFree(Pointer<Void> ptr);
