import 'dart:convert';

/// The `data:` payloads of a server-sent-events body, one per event. Lines
/// may arrive split across chunks; `[DONE]` markers are left for the caller.
Stream<String> sseData(Stream<List<int>> bytes) async* {
  final data = <String>[];
  await for (final line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield data.join('\n');
      data.clear();
    } else if (line.startsWith('data:')) {
      data.add(line.substring(5).trimLeft());
    }
  }
  if (data.isNotEmpty) yield data.join('\n');
}
