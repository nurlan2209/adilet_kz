import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ActCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String status;
  final String? id;
  final VoidCallback? onTap;

  const ActCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.id,
    this.onTap,
  });

  @override
  State<ActCard> createState() => _ActCardState();
}

class _ActCardState extends State<ActCard> {
  bool _isFavorite = false;
  late final dynamic _uniqueId;

  @override
  void initState() {
    super.initState();
    _uniqueId = widget.id ?? widget.title;
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final storage = await StorageService.getInstance();
    final fav = storage.isFavorite(_uniqueId);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Color _statusColor() {
    final s = widget.status.toLowerCase();
    if (s.contains('действ')) return Colors.green;
    if (s.contains('измен')) return Colors.orange;
    return Colors.red;
  }

  Future<void> _toggleFavorite() async {
    final storage = await StorageService.getInstance();
    if (_isFavorite) {
      await storage.removeFavoriteById(_uniqueId);
      if (mounted) setState(() => _isFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено из избранного')));
    } else {
      final act = {
        'id': widget.id ?? widget.title,
        'title': widget.title,
        'subtitle': widget.subtitle,
        'status': widget.status,
      };
      await storage.addFavorite(act);
      if (mounted) setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено в избранное')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: const Icon(Icons.article_outlined),
        title: Text(widget.title),
        subtitle: Text(widget.subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.status, style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            IconButton(
              icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }
}
