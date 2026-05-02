import 'package:isar/isar.dart';

part 'cached_file.g.dart';

@collection
class CachedFile {
  Id id = Isar.autoIncrement;
  
  late String path;
  late String name;
  late int size;
  late int serverId;
  DateTime? cachedAt;
}
