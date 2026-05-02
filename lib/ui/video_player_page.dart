import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/server_record.dart';
import '../services/player_service.dart';
import '../services/stream_proxy_server.dart';

class VideoPlayerPage extends StatefulWidget {
  final ServerRecord server;
  final String filePath;
  final String fileName;

  const VideoPlayerPage({
    super.key,
    required this.server,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final PlayerService _playerService = PlayerService();
  late final VideoController _videoController;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _playerService.initialize();
    await StreamProxyServer().start();
    
    _videoController = VideoController(
      _playerService.player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    await _playerService.playVideo(
      widget.filePath,
      fileName: widget.fileName,
      serverId: widget.server.id,
    );

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    StreamProxyServer().stop();
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                children: [
                  Video(controller: _videoController),
                  if (_showControls)
                    _buildControls(),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.fileName),
          ),
          const Expanded(child: SizedBox()),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: _playerService.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _playerService.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;
                  return Column(
                    children: [
                      Slider(
                        value: position.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _playerService.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, size: 32),
                color: Colors.white,
                onPressed: () {
                  _playerService.seek(
                    _playerService.position - const Duration(seconds: 10),
                  );
                },
              ),
              const SizedBox(width: 16),
              StreamBuilder<bool>(
                stream: _playerService.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                    ),
                    color: Colors.white,
                    onPressed: () {
                      if (isPlaying) {
                        _playerService.pause();
                      } else {
                        _playerService.resume();
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10, size: 32),
                color: Colors.white,
                onPressed: () {
                  _playerService.seek(
                    _playerService.position + const Duration(seconds: 10),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
