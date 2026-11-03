import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Builds libcamera_linux.so from src/ with the C compiler the Dart or
/// Flutter SDK hands us. The library only talks to the kernel's V4L2 API, so
/// there is nothing to find or link against.
///
/// On every other target OS the hook produces no asset: the Dart API throws
/// an [UnsupportedError] there before any native symbol is looked up.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.linux) return;

    final builder = CBuilder.library(
      name: 'camera_linux',
      assetName: 'src/bindings.dart',
      sources: ['src/camera_linux.c'],
      includes: ['src'],
      language: Language.c,
      std: 'c11',
      flags: [
        '-fvisibility=hidden',
        '-pthread',
        '-Wall',
        '-Wextra',
        '-Wno-unused-function',
        '-Wno-missing-field-initializers',
        // Keep the shared object self-contained.
        '-Wl,--exclude-libs,ALL',
        '-Wl,-z,relro',
        '-Wl,-z,now',
      ],
    );
    await builder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => print(record.message)),
    );
  });
}
