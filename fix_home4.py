code = open('lib/screens/home_screen.dart').read()
old = "  Widget _buildMovies()"
new = """  Widget _buildChannelList(List<dynamic> items) => SizedBox(height: 90,
    child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final c = items[i];
        return GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlayerScreen(channel: c['channel']))),
          child: Container(width: 120, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CachedNetworkImage(imageUrl: c['poster'] ?? '', height: 45, width: 80, fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 30)),
              const SizedBox(height: 4),
              Text(c['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ])));
      }));

  Widget _buildMovies()"""
code = code.replace(old, new)
open('lib/screens/home_screen.dart','w').write(code)
print('OK')
