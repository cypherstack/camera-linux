# camera_linux

Captures JPEG frames from a webcam on Linux through `dart:ffi`, for Flutter
and plain Dart programs.

The native part is a single C file that talks to the kernel's V4L2 API
directly and is compiled by a [build hook](https://dart.dev/tools/hooks)
(`hook/build.dart`) when the app is built. There is nothing to install and
nothing to bundle by hand: no OpenCV, no CMake plugin, no system packages
beyond a C compiler and the kernel headers that every distribution ships with
its toolchain. The resulting `libcamera_linux.so` depends on libc only.

## Requirements

- Dart 3.10 or Flutter 3.38 or newer (build hooks are enabled by default
  there). The package is a plain Dart package, so it also works outside
  Flutter, for example under `dart test` and `dart run`.
- A C compiler on the build machine. The hook uses the one the SDK finds
  (`clang` or `gcc`).
- A Flutter app's `linux/CMakeLists.txt` must contain the "native assets"
  install block that `flutter create` has generated since Flutter 3.24:

  ```cmake
  set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
     DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
     COMPONENT Runtime)
  ```

  Older runners miss it and the library would not be copied into
  `bundle/lib`.

At run time the user needs read and write access to the `/dev/video*` node,
which desktop distributions grant through the `video` group or logind.
Inside a Flatpak that means `--device=all` (or an explicit `--device=input`
plus the camera portal).

## Usage

```dart
import 'package:camera_linux/camera_linux.dart';

final camera = CameraLinux();

// Which devices would be tried, in order.
print(CameraLinux.availableDevices());

// Opens the first usable device (or the one named in CAMERA_LINUX_DEVICE)
// and starts a capture thread. Throws CameraLinuxException on failure.
await camera.initializeCamera();

// Each frame is handed out once; null means nothing new has arrived yet.
final Uint8List? jpeg = camera.captureJpeg();

// Compatibility API: the same frame, base64url encoded ('' when none).
final String base64 = await camera.captureImage();

camera.stopCamera();
```

`initializeCamera` accepts a `devicePath`, a requested `width` and `height`
(the driver may pick another size, see `frameSize`) and a `jpegQuality`.

## How frames are produced

The capture thread streams with memory-mapped buffers and keeps only the
newest frame. On `captureJpeg()`:

- MJPEG/JPEG cameras: the frame is passed through. UVC cameras often omit the
  Huffman tables from their MJPEG frames, which makes Skia and `package:image`
  reject them, so the standard tables are inserted when missing.
- YUYV, UYVY, YVYU, VYUY, NV12, NV21, YU12, YV12, RGB24, BGR24 and GREY
  frames are converted and encoded with the public-domain
  [stb_image_write](https://github.com/nothings/stb) encoder vendored in
  `src/`.

Uncompressed formats are preferred when a camera offers both, so that the
JPEG the app sees is the same for every camera. Device nodes that are not
streaming video capture devices (UVC metadata nodes, for example) are
skipped.

## Development

```sh
dart test            # builds the hook, runs the unit tests
cd example && flutter run -d linux
```

The test suite covers the pixel-format conversions, the encoder and the
MJPEG repair without hardware. One test streams from a real camera and is
skipped when none is attached. To exercise it without a webcam load
`v4l2loopback` and feed it frames with `tool/v4l2loopback_feed.py` (needs
numpy and Pillow; `qrcode` for a real QR code):

```sh
sudo modprobe v4l2loopback video_nr=42 card_label=test exclusive_caps=1
python3 tool/v4l2loopback_feed.py /dev/video42 --format yuyv --text 'hello' &
CAMERA_LINUX_DEVICE=/dev/video42 dart test
```

`--format mjpeg --strip-dht` reproduces cameras whose MJPEG frames lack
Huffman tables.

## License

BSD 3-Clause (see `LICENSE`). `src/stb_image_write.h` is public domain
(or MIT, at your option) by Sean Barrett and contributors.
