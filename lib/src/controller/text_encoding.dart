import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Encodings a log file may use. Logs captured with a shell redirect on
/// Windows (`adb logcat > log.txt` in PowerShell 5) are UTF-16LE.
enum TextEncoding {
  utf8('UTF-8', 1),
  utf16le('UTF-16LE', 2),
  utf16be('UTF-16BE', 2),
  utf32le('UTF-32LE', 4),
  utf32be('UTF-32BE', 4);

  const TextEncoding(this.label, this.unitSize);

  final String label;
  final int unitSize;

  bool get isWide => this != utf8;

  /// Decoder that turns the file's bytes into text, keeping code units and
  /// surrogate pairs that are split across chunks intact.
  StreamTransformer<List<int>, String> get decoder => switch (this) {
        utf8 => const Utf8Decoder(allowMalformed: true),
        _ => _WideDecoder(this),
      };
}

/// How a file is encoded and how many leading BOM bytes to skip.
class DetectedEncoding {
  const DetectedEncoding(this.encoding, this.bomLength);
  final TextEncoding encoding;
  final int bomLength;
}

/// Sniffs [file]'s encoding from its byte order mark or, without one, from
/// the pattern of zero bytes that UTF-16 gives ASCII text.
Future<DetectedEncoding> detectEncoding(File file) async {
  final raf = await file.open();
  final Uint8List head;
  try {
    head = await raf.read(4096);
  } finally {
    await raf.close();
  }
  bool starts(List<int> bom) {
    if (head.length < bom.length) return false;
    for (var i = 0; i < bom.length; i++) {
      if (head[i] != bom[i]) return false;
    }
    return true;
  }

  // UTF-32LE's BOM starts with UTF-16LE's, so check it first.
  if (starts([0xFF, 0xFE, 0, 0])) {
    return const DetectedEncoding(TextEncoding.utf32le, 4);
  }
  if (starts([0, 0, 0xFE, 0xFF])) {
    return const DetectedEncoding(TextEncoding.utf32be, 4);
  }
  if (starts([0xFF, 0xFE])) {
    return const DetectedEncoding(TextEncoding.utf16le, 2);
  }
  if (starts([0xFE, 0xFF])) {
    return const DetectedEncoding(TextEncoding.utf16be, 2);
  }
  if (starts([0xEF, 0xBB, 0xBF])) {
    return const DetectedEncoding(TextEncoding.utf8, 3);
  }

  final pairs = head.length ~/ 2;
  if (pairs >= 8) {
    var evenZeros = 0, oddZeros = 0;
    for (var i = 0; i + 1 < head.length; i += 2) {
      if (head[i] == 0) evenZeros++;
      if (head[i + 1] == 0) oddZeros++;
    }
    // Mostly-ASCII UTF-16 has a zero in every other byte; UTF-8 text has
    // practically none.
    if (oddZeros > pairs * 0.4 && evenZeros < pairs * 0.05) {
      return const DetectedEncoding(TextEncoding.utf16le, 0);
    }
    if (evenZeros > pairs * 0.4 && oddZeros < pairs * 0.05) {
      return const DetectedEncoding(TextEncoding.utf16be, 0);
    }
  }
  return const DetectedEncoding(TextEncoding.utf8, 0);
}

class _WideDecoder extends StreamTransformerBase<List<int>, String> {
  const _WideDecoder(this.encoding);

  final TextEncoding encoding;

  @override
  Stream<String> bind(Stream<List<int>> stream) async* {
    final size = encoding.unitSize;
    final bigEndian =
        encoding == TextEncoding.utf16be || encoding == TextEncoding.utf32be;
    var carry = <int>[];
    await for (final chunk in stream) {
      final bytes = carry.isEmpty ? chunk : [...carry, ...chunk];
      final usable = bytes.length - bytes.length % size;
      final units = <int>[];
      for (var i = 0; i < usable; i += size) {
        var v = 0;
        for (var b = 0; b < size; b++) {
          v |= bytes[i + (bigEndian ? size - 1 - b : b)] << (8 * b);
        }
        // Invalid code points become U+FFFD.
        units.add(v > 0x10FFFF ? 0xFFFD : v);
      }
      carry = bytes.sublist(usable);
      // UTF-16 code units go in as-is: a surrogate pair split across chunks
      // is rejoined when LineSplitter concatenates the pieces.
      if (units.isNotEmpty) yield String.fromCharCodes(units);
    }
    if (carry.isNotEmpty) yield '\uFFFD';
  }
}
