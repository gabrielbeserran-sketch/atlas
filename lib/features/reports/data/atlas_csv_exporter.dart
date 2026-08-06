
import 'dart:convert';
import 'dart:typed_data';

class AtlasCsvExporter {
  const AtlasCsvExporter();

  Uint8List encode(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) {
      return Uint8List.fromList(utf8.encode(''));
    }

    final headers = <String>{
      for (final row in rows) ...row.keys,
    }.toList();

    String cell(dynamic value) {
      final text = value is Map || value is List
          ? jsonEncode(value)
          : value?.toString() ?? '';
      return '"${text.replaceAll('"', '""')}"';
    }

    final buffer = StringBuffer()
      ..writeln(headers.map(cell).join(','));

    for (final row in rows) {
      buffer.writeln(
        headers.map((header) => cell(row[header])).join(','),
      );
    }

    return Uint8List.fromList(
      utf8.encode('\uFEFF${buffer.toString()}'),
    );
  }
}
