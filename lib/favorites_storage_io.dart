import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _file(String name) async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return File('${directory.path}/$name.json');
}

Future<String?> readFavorites({String name = 'waznah_favorites'}) async {
  final file = await _file(name);
  return await file.exists() ? file.readAsString() : null;
}

Future<void> writeFavorites(
  String value, {
  String name = 'waznah_favorites',
}) async {
  final file = await _file(name);
  final temporary = File('${file.path}.tmp');
  await temporary.writeAsString(value, flush: true);
  await temporary.rename(file.path);
}
