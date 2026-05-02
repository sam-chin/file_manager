import 'package:isar/isar.dart';

part 'playback_history.g.dart';

@collection
class PlaybackHistory {
  Id id = Isar.autoIncrement;
  
  late String filePath;
  late String fileName;
  late int serverId;
  late Duration position;
  late Duration duration;
  DateTime lastPlayed = DateTime.now();
  int playCount = 1;
}
