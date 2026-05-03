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
              Positioned(
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
                  ],
                ),
              ),
              if (service.currentType == FileItemType.video || service.currentType == FileItemType.audio)
                _buildCenterControls(service),
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

  Widget _buildCenterControls(MediaService service) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 45),
              onPressed: service.playPrevious,
            ),
            const SizedBox(width: 30),
            IconButton(
              icon: Icon(
                service.isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
                size: 85,
              ),
              onPressed: () => service.togglePlay(),
            ),
            const SizedBox(width: 30),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 45),
              onPressed: service.playNext,
            ),
          ],
        ),
      ),
    );
  }
}
