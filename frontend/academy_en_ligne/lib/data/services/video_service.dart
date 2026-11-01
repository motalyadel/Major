import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';

class VideoService {
  final _client = Supabase.instance.client;

  /// YouTube ID ou null
  String? extractYoutubeId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return null;
  }

  bool isYoutube(String? url) {
    if (url == null || url.isEmpty) return false;
    return extractYoutubeId(url) != null;
  }

  bool isHttpUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Retourne une URL jouable, ou null si accès refusé / erreur
  Future<String?> getPlayableUrl({
    required Lesson lesson,
    required bool isSubscribed,
  }) async {
    final raw = lesson.videoUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    // Verrouillage premium
    if (lesson.isLocked(isSubscribed)) {
      return null;
    }

    // YouTube ou URL HTTP directe (tests)
    if (isHttpUrl(raw)) {
      return raw;
    }

    // Chemin Storage → signed URL (1 heure)
    try {
      final signed = await _client.storage
          .from('videos')
          .createSignedUrl(raw, 3600);
      return signed;
    } catch (e, s) {
      debugPrint('createSignedUrl error: $e\n$s');
      return null;
    }
  }
}