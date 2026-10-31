import 'package:web/web.dart' as web;

String _key(String name) =>
    name == 'waznah_favorites' ? 'waznah.favorites.v1' : '$name.v1';
Future<String?> readFavorites({String name = 'waznah_favorites'}) async =>
    web.window.localStorage.getItem(_key(name));
Future<void> writeFavorites(
  String value, {
  String name = 'waznah_favorites',
}) async => web.window.localStorage.setItem(_key(name), value);
