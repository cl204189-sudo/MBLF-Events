import 'package:shared_preferences/shared_preferences.dart';

class FavoritoService {
  static const String _chave = 'eventos_favoritos';

  Future<Set<int>> listarIds() async {
    final prefs =
        await SharedPreferences.getInstance();

    final lista =
        prefs.getStringList(_chave) ?? [];

    return lista
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();
  }

  Future<bool> isFavorito(
    int eventoId,
  ) async {
    final favoritos =
        await listarIds();

    return favoritos.contains(
      eventoId,
    );
  }

  Future<void> adicionar(
    int eventoId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final favoritos =
        await listarIds();

    favoritos.add(eventoId);

    await prefs.setStringList(
      _chave,
      favoritos
          .map((id) => id.toString())
          .toList(),
    );
  }

  Future<void> remover(
    int eventoId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final favoritos =
        await listarIds();

    favoritos.remove(eventoId);

    await prefs.setStringList(
      _chave,
      favoritos
          .map((id) => id.toString())
          .toList(),
    );
  }

  Future<bool> alternar(
    int eventoId,
  ) async {
    final favorito =
        await isFavorito(eventoId);

    if (favorito) {
      await remover(eventoId);
      return false;
    }

    await adicionar(eventoId);

    return true;
  }
}