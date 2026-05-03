import 'package:flutter/material.dart';
import '../services/player_service.dart';

class GlobalPlayerBar extends StatefulWidget {
  const GlobalPlayerBar({super.key});

  @override
  State<GlobalPlayerBar> createState() => _GlobalPlayerBarState();
}

class _GlobalPlayerBarState extends State<GlobalPlayerBar> {
  final PlayerService _player = PlayerService();

  @override
  void initState() {
    super.initState();
    _player.onPlayingChanged.listen((playing) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_player.currentFile == null) return const SizedBox.shrink();

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ListTile(
          leading: Icon(
            _player.isVideo ? Icons.video_library : Icons.music_note,
            color: Colors.white,
          ),
          title: Text(
            _player.currentFile?.name ?? "",
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: StreamBuilder<Duration>(
            stream: _player.onPositionChanged,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player.onDurationChanged,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;
                  if (duration.inSeconds > 0) {
                    return LinearProgressIndicator(
                      value: position.inMilliseconds / duration.inMilliseconds,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    );
                  }
                  return const LinearProgressIndicator(
                    value: 0,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  );
                },
              );
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: () {
                  if (_player.isPlaying) {
                    _player.pause();
                  } else {
                    _player.resume();
                  }
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: () {
                  _player.stop();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
