import 'dart:convert';
import 'dart:io';

import 'package:waznah/catalog_snapshot.dart';

void main(List<String> args) {
  if (args.isNotEmpty &&
      args.first == 'prepare' &&
      (args.length == 3 || args.length == 4)) {
    final current = readCatalog(File(args[1]));
    final source = args.length == 4 ? readCatalog(File(args[3])) : current;
    final sourceIds = source.parts.map((part) => part.id).toSet();
    if (current.parts.any((part) => !sourceIds.contains(part.id))) {
      throw StateError(
        'Keep existing part IDs when restoring an older version',
      );
    }
    final json = source.toJson()..['revision'] = current.revision + 1;
    CatalogSnapshot.fromJson(json);
    final encoded = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
    if (utf8.encode(encoded).length > 750000) {
      throw StateError('Catalog exceeds publication size limit');
    }
    final output = File(args[2]);
    // Exclusive creation: no replacement of a previous draft or input file.
    output.parent.createSync(recursive: true);
    output.createSync(exclusive: true);
    output.writeAsStringSync(encoded, flush: true);
    stdout.writeln('Prepared revision ${json['revision']}; nothing published');
    return;
  }
  if (args.length != 2 || !['export', 'validate'].contains(args.first)) {
    stderr.writeln(
      'Usage: dart run tool/catalog.dart export|validate FILE\n'
      '       dart run tool/catalog.dart prepare CURRENT OUTPUT [RESTORE]',
    );
    exitCode = 1;
    return;
  }
  final file = File(args[1]);
  if (args.first == 'export') {
    if (file.existsSync()) {
      throw StateError('Refusing to replace an existing draft');
    }
    final json = CatalogSnapshot.bundled.toJson()..['revision'] = 1;
    CatalogSnapshot.fromJson(json);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }
  final data = readCatalog(file);
  stdout.writeln(
    'Valid revision ${data.revision}: ${data.parts.length} parts, '
    '${data.workshops.length} workshops, ${data.services.length} services',
  );
}

CatalogSnapshot readCatalog(File file) {
  final bytes = file.readAsBytesSync();
  if (bytes.length > 750000) {
    throw StateError('Catalog exceeds publication size limit');
  }
  final data = CatalogSnapshot.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );
  if (data.parts.isEmpty) throw StateError('Refusing an empty catalog');
  return data;
}
