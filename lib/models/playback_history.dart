import 'package:isar/isar.dart';

// 必须包含这一行，且文件名要匹配
part 'playback_history.g.dart';

@collection
class PlaybackHistory {
  Id id = Isar.autoIncrement;
  late String fileUrl;
  late int positionInMs;
}
