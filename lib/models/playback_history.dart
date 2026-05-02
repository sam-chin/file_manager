import 'package:isar/isar.dart';

part 'playback_history.g.dart';

@collection
class PlaybackHistory {
  Id id = Isar.autoIncrement;

  late String fileUrl;
  late String fileName;
  late int serverId;

  // Isar 不支持 Duration，改存毫秒数
  late int positionInMs;
  late int durationInMs;

  DateTime lastPlayed = DateTime.now();
  int playCount = 1;

  // 提供方便的转换方法
  @ignore
  Duration get position => Duration(milliseconds: positionInMs);

  @ignore
  Duration get duration => Duration(milliseconds: durationInMs);

  set position(Duration value) {
    positionInMs = value.inMilliseconds;
  }

  set duration(Duration value) {
    durationInMs = value.inMilliseconds;
  }
}
