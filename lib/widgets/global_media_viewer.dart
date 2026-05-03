import 'package:flutter/material.dart';
import 'dart:io';
import '../services/media_service.dart';

class GlobalMediaViewer extends StatelessWidget {
  const GlobalMediaViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MediaService(),
      builder: (context, _) {
        final service = MediaService();
        if (service.category == MediaCategory.none) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _buildContent(service, context),
              _buildTopBar(service, context),
              if (service.category != MediaCategory.image)
                _buildCenterControls(service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(MediaService service, BuildContext context) {
    if (service.category == MediaCategory.image) {
      return PageView.builder(
        itemCount: service.playlist.length,
        controller: PageController(initialPage: service.currentIndex),
        onPageChanged: (index) {
          if (index != service.currentIndex) {
            final file = service.playlist[index];
            service.open(file, service.playlist);
          }
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
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
            ),
          );
        },
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            service.category == MediaCategory.video ? Icons.movie : Icons.music_note,
            color: Colors.white30,
            size: 120,
          ),
          const SizedBox(height: 20),
          Text(
            service.currentName,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(MediaService service, BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => service.close(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service.currentName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildCenterControls(MediaService service) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.skip_previous,
              color: service.hasPrevious ? Colors.white : Colors.white38,
              size: 50,
            ),
            onPressed: service.hasPrevious ? () => service.previous() : null,
          ),
          IconButton(
            icon: Icon(
              service.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white,
              size: 80,
            ),
            onPressed: () => service.togglePlay(),
          ),
          IconButton(
            icon: Icon(
              Icons.skip_next,
              color: service.hasNext ? Colors.white : Colors.white38,
              size: 50,
            ),
            onPressed: service.hasNext ? () => service.next() : null,
          ),
        ],
      ),
    );
  }
}
