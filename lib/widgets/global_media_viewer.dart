import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_service.dart';
import '../models/file_item.dart';

class GlobalMediaViewer extends StatelessWidget {
  const GlobalMediaViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MediaService(),
      builder: (context, _) {
        final service = MediaService();
        
        if (service.currentType == FileItemType.other || 
            service.currentType == FileItemType.folder ||
            service.currentFile == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _buildMainContent(service),
              _buildTopBar(service, context),
              if (service.currentType == FileItemType.video || service.currentType == FileItemType.audio)
                _buildPlayerUI(service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(MediaService service) {
    if (service.currentType == FileItemType.image) {
      return PageView.builder(
        itemCount: service.playlist.length,
        controller: PageController(initialPage: service.currentIndex),
        onPageChanged: (index) => service.updateIndex(index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Image.file(
              File(service.playlist[index].path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 64),
                      SizedBox(height: 16),
                      Text('无法加载图片', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    }
    return Center(
      child: Icon(
        service.currentType == FileItemType.video ? Icons.movie : Icons.music_note,
        color: Colors.white10,
        size: 200,
      ),
    );
  }

  Widget _buildTopBar(MediaService service, BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
            onPressed: () => service.close(),
          ),
          Expanded(
            child: Text(
              service.currentName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (service.playlist.length > 1)
            Text(
              '${service.currentIndex + 1} / ${service.playlist.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerUI(MediaService service) {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Slider(
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white24,
              value: service.currentPosition.inSeconds.toDouble().clamp(0, service.totalDuration.inSeconds.toDouble()),
              max: service.totalDuration.inSeconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) {
                service.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(service.currentPosition),
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  _formatDuration(service.totalDuration),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  size: 40,
                  color: service.hasPrevious ? Colors.white : Colors.white38,
                ),
                onPressed: service.hasPrevious ? () => service.playPrevious() : null,
              ),
              IconButton(
                icon: Icon(
                  service.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 80,
                  color: Colors.white,
                ),
                onPressed: () => service.togglePlay(),
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  size: 40,
                  color: service.hasNext ? Colors.white : Colors.white38,
                ),
                onPressed: service.hasNext ? () => service.playNext() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
