## 0.1.0

* Rewritten on top of V4L2 with a Dart build hook (`hook/build.dart`); the
  package is now a plain Dart package rather than a CMake FFI plugin.
* OpenCV is no longer needed, at build time or at run time. The shared object
  depends on libc only and is bundled automatically by Flutter.
* MJPEG cameras are passed through (with missing Huffman tables repaired);
  YUYV, UYVY, YVYU, VYUY, NV12, NV21, YU12, YV12, RGB24, BGR24 and GREY are
  converted and encoded here.
* New API: `CameraLinux.availableDevices()`, `captureJpeg()`, `isRunning`,
  `frameSize`, `devicePath`, `initializeCamera(devicePath:, width:, height:,
  jpegQuality:)`; failures throw `CameraLinuxException` instead of printing.
* `captureImage()` keeps returning a base64url JPEG and now returns an empty
  string, rather than throwing, when no new frame is available.
* Frames returned to Dart are allocated with `malloc`, matching how they are
  freed.

## 0.0.8

* OpenCV static dependencies removed

## 0.0.7

* OpenCV Dependencies added statically

## 0.0.6

* Dart SDK version changed to 3.1.0

## 0.0.5

* Converted API functions into asyc functions.

## 0.0.4

* Code refractor

## 0.0.3

* Created API for storing frame into Base64 Image.

## 0.0.2

* Fixes in core API.

## 0.0.1

* Initial release.
