class Channel {
  final String id, name, category, logoUrl, streamUrl;
  final Map<String, String> headers;
  final bool isLive;
  final String? epgNow, epgNext;
  final int? number;
  const Channel({required this.id, required this.name, required this.category, required this.logoUrl, required this.streamUrl, this.headers = const {}, this.isLive = true, this.epgNow, this.epgNext, this.number});
}

enum ContentType { movie, series }

class Content {
  final String id, title, posterUrl;
  final ContentType type;
  final String? year, rating, description, streamUrl, backdropUrl, category;
  final Map<String, String> headers;
  final List<Episode> episodes;
  const Content({required this.id, required this.title, required this.posterUrl, required this.type, this.year, this.rating, this.description, this.streamUrl, this.backdropUrl, this.category, this.headers = const {}, this.episodes = const []});
}

class Episode {
  final String id, title, streamUrl;
  final int season, episode;
  final String? thumbnailUrl;
  final Map<String, String> headers;
  const Episode({required this.id, required this.title, required this.season, required this.episode, required this.streamUrl, this.thumbnailUrl, this.headers = const {}});
}

class UserProfile {
  final int id;
  final String name, avatarEmoji;
  const UserProfile({required this.id, required this.name, required this.avatarEmoji});
}
