import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class VideoPlayerPage extends StatefulWidget {
  final Lesson lesson;

  const VideoPlayerPage({super.key, required this.lesson});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.lesson.videoUrl?.trim();

    if (url == null || url.isEmpty) {
      setState(() {
        _initializing = false;
        _error = 'Aucune vidéo disponible pour cette leçon.';
      });
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey.shade700,
          bufferedColor: Colors.grey.shade400,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Écouter le buffering
      _videoController!.addListener(_onVideoUpdate);

      if (mounted) {
        setState(() {
          _initializing = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Impossible de charger la vidéo.\n$e';
        });
      }
    }
  }

  bool _isBuffering = false;

  void _onVideoUpdate() {
    if (_videoController == null || !mounted) return;

    final value = _videoController!.value;
    final buffering = value.isBuffering;

    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _chewieController?.dispose();
    _videoController?.dispose();
    // Restaurer l'orientation si besoin
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.lesson.title,
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Zone vidéo ----
            AspectRatio(
              aspectRatio: _videoController?.value.isInitialized == true
                  ? _videoController!.value.aspectRatio
                  : 16 / 9,
              child: _buildVideoArea(),
            ),

            // ---- Infos leçon ----
            Expanded(
              child: Container(
                color: const Color(0xFFF5F7FB),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (widget.lesson.isFree)
                          _chip('Gratuit', Colors.green)
                        else
                          _chip('Premium', Colors.orange),
                        if (widget.lesson.durationLabel.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.schedule,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            widget.lesson.durationLabel,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isBuffering) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Chargement…',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_initializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Préparation de la vidéo…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _initializing = true;
                    _error = null;
                  });
                  _initPlayer();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Chewie(controller: _chewieController!),
          // Indicateur buffering par-dessus
          if (_isBuffering)
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}