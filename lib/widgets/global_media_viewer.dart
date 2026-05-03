import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_service.dart';

class GlobalMediaViewer extends StatelessWidget {
  const GlobalMediaViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MediaService(),
      builder: (context, _) {
        final service = MediaService();
        if (service.currentCategory == MediaCategory.none) return const SizedBox.shrink();

        if (service.currentCategory == MediaCategory.image) {
          return _buildImageViewer(service);
        }
        
        if (service.currentCategory == MediaCategory.audio) {
          return _buildBottomAudioBar(service);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildImageViewer(MediaService service) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: service.currentPath != null
                  ? Image.file(
                      File(service.currentPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => service.close(),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  service.currentName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAudioBar(MediaService service) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blueGrey.shade900,
          child: SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.music_note, color: Colors.white),
              title: Text(
                service.currentName,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      service.isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      if (service.isPlaying) {
                        service.pause();
                      } else {
                        service.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => service.close(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
