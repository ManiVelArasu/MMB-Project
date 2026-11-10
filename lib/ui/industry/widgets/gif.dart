import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class _GifJob {
  final List<String> paths;
  final int delayCentiSeconds;
  const _GifJob(this.paths, this.delayCentiSeconds);
}

Uint8List? _encodeGifJob(_GifJob job) {
  final encoder = img.GifEncoder(
    delay: job.delayCentiSeconds,
    repeat: 0,
    samplingFactor: 20,
  );
  for (final path in job.paths) {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) continue;
    encoder.addFrame(decoded, duration: job.delayCentiSeconds);
  }
  return encoder.finish();
}

/// GIF / MP4 encoding of the PNG frames captured by the editor.
class ExportEncoder {
  /// Encodes the PNG frame files into a looping GIF (off the UI thread).
  static Future<Uint8List?> encodeGif(List<String> framePaths, int fps) {
    return compute(_encodeGifJob, _GifJob(framePaths, (100 / fps).round()));
  }

  /// Encodes `f_0000.png ...` in [framesDir] into an H.264 MP4.
  /// [audioPath] (optional) is mixed in and trimmed to the video length.
  static Future<bool> encodeMp4({
    required String framesDir,
    required int fps,
    required String outPath,
    String? audioPath,
  }) async {
    final hasAudio = audioPath != null && audioPath.isNotEmpty;
    final cmd = StringBuffer()
      ..write('-y -framerate $fps -i "$framesDir/f_%04d.png" ')
      ..write(hasAudio ? '-i "$audioPath" ' : '')
      ..write('-c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p ')
      ..write('-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" ')
      ..write(hasAudio ? '-c:a aac -shortest ' : '')
      ..write('-movflags +faststart "$outPath"');

    final session = await FFmpegKit.execute(cmd.toString());
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      debugPrint('FFmpeg failed: ${await session.getAllLogsAsString()}');
      return false;
    }
    return true;
  }
}