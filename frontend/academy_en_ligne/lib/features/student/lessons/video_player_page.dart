import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:academy_en_ligne/data/models/lesson_model.dart';
import 'package:academy_en_ligne/data/services/video_service.dart';
import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart';

class VideoPlayerPage extends StatefulWidget {
  final Lesson lesson;

  const VideoPlayerPage({super.key, required this.lesson});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final _videoService = VideoService();

  YoutubePlayerController? _ytController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isYoutube = false;
  bool _initializing = true;
  bool _isBuffering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  Future<void> _initPlayer() async {
    try {
      final isSubscribed = context.read<AuthController>().isSubscribed;

      if (widget.lesson.isLocked(isSubscribed)) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = 'Cette leçon est réservée aux abonnés.';
        });
        return;
      }

      final playableUrl = await _videoService
          .getPlayableUrl(lesson: widget.lesson, isSubscribed: isSubscribed)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (playableUrl == null || playableUrl.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'Vidéo indisponible (URL ou Storage).';
        });
        return;
      }

      debugPrint('Playable URL: $playableUrl');

      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(playableUrl));
      await _videoController!.initialize().timeout(const Duration(seconds: 20));
      // ... Chewie comme avant ...

      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = null;
      });
    } catch (e, s) {
      debugPrint('Init player error: $e\n$s');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Impossible de charger la vidéo.\n$e';
      });
    }
  }

  void _onVideoUpdate() {
    if (_videoController == null || !mounted) return;
    final buffering = _videoController!.value.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _ytController?.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // Zone vidéo (hauteur fixe, pas Expanded ici)
                    SizedBox(
                      width: double.infinity,
                      height: constraints.maxWidth * 9 / 16, // 16:9
                      child: _buildPlayerArea(),
                    ),
                    // Infos
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF5F7FB),
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
                          Text(
                            widget.lesson.isFree ? 'Gratuit' : 'Premium',
                            style: TextStyle(
                              color: widget.lesson.isFree
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isBuffering) ...[
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Chargement…'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_initializing) {
      return const Center(
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
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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

    if (_isYoutube && _ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
      );
    }

    if (_chewieController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Chewie(controller: _chewieController!),
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
