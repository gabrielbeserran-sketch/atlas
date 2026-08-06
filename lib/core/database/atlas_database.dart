abstract class AtlasDatabase {
  Future<void> initialize();
  Future<T?> read<T>(String key);
  Future<void> write<T>(String key, T value);
  Future<void> delete(String key);
  Future<List<String>> keys();
}

abstract class AtlasRepositoryBase<T> {
  Future<List<T>> findAll();
  Future<T?> findById(String id);
  Future<void> save(T item);
  Future<void> remove(String id);
}

class AtlasMigration {
  const AtlasMigration({
    required this.version,
    required this.description,
    required this.completed,
  });

  final int version;
  final String description;
  final bool completed;
}
