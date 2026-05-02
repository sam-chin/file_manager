import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/server_record.dart';
import '../models/playback_history.dart';
import '../models/cached_file.dart';

class DatabaseService {
  static late final Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ServerRecordSchema, PlaybackHistorySchema, CachedFileSchema],
      directory: dir.path,
    );
  }

  static Future<List<ServerRecord>> getAllServers() async {
    return isar.serverRecords.where().findAll();
  }

  static Future<ServerRecord?> getServer(int id) async {
    return isar.serverRecords.get(id);
  }

  static Future<void> saveServer(ServerRecord server) async {
    await isar.writeTxn(() async {
      await isar.serverRecords.put(server);
    });
  }

  static Future<void> deleteServer(int id) async {
    await isar.writeTxn(() async {
      await isar.serverRecords.delete(id);
    });
  }

  static Future<PlaybackHistory?> getPlaybackHistory(String filePath) async {
    return isar.playbackHistorys
        .filter()
        .filePathEqualTo(filePath)
        .findFirst();
  }

  static Future<List<PlaybackHistory>> getRecentPlaybackHistory({int limit = 20}) async {
    return isar.playbackHistorys
        .where()
        .sortByLastPlayedDesc()
        .limit(limit)
        .findAll();
  }

  static Future<void> savePlaybackHistory(PlaybackHistory history) async {
    await isar.writeTxn(() async {
      await isar.playbackHistorys.put(history);
    });
  }

  static Future<List<CachedFile>> getCachedFiles(int serverId) async {
    return isar.cachedFiles
        .filter()
        .serverIdEqualTo(serverId)
        .findAll();
  }

  static Future<void> saveCachedFile(CachedFile file) async {
    await isar.writeTxn(() async {
      await isar.cachedFiles.put(file);
    });
  }

  static Future<void> saveCachedFiles(List<CachedFile> files) async {
    await isar.writeTxn(() async {
      await isar.cachedFiles.putAll(files);
    });
  }

  static Future<void> clearCache(int serverId) async {
    await isar.writeTxn(() async {
      await isar.cachedFiles
          .filter()
          .serverIdEqualTo(serverId)
          .deleteAll();
    });
  }
}
