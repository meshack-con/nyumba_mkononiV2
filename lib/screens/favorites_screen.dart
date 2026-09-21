import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'property_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteItem> _favorites = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!await ensureAuthenticated(context, asSeller: false)) { if (mounted) setState(() => _loading = false); return; }
    try { final data = await ApiClient.instance.getFavorites(); if (mounted) setState(() => _favorites = data); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _remove(Property property) async {
    await ApiClient.instance.removeFavorite(property.id);
    if (mounted) setState(() => _favorites.removeWhere((item) => item.property.id == property.id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 24), children: [Text('Zilizopendwa', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('Nyumba ulizoweka pembeni.', style: TextStyle(color: AppTheme.muted)), const SizedBox(height: 24), if (_loading) const Center(child: CircularProgressIndicator()) else if (_favorites.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Column(children: [Icon(Icons.favorite_border_rounded, size: 48, color: AppTheme.muted), SizedBox(height: 12), Text('Bado hujapenda nyumba yoyote.', style: TextStyle(color: AppTheme.muted))])) else ..._favorites.map((item) => _FavoriteTile(item: item, onRemove: () => _remove(item.property), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: item.property))))) ])));
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.item, required this.onRemove, required this.onTap});
  final FavoriteItem item; final VoidCallback onRemove; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.all(8), leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 70, height: 70, child: item.property.photoUrls.isEmpty ? const ColoredBox(color: AppTheme.sand, child: Icon(Icons.home)) : Image.network(ApiClient.instance.assetUrl(item.property.photoUrls.first), fit: BoxFit.cover))), title: Text(item.property.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(item.property.formattedPrice, style: TextStyle(color: AppTheme.coral, fontWeight: FontWeight.w700)), trailing: IconButton(onPressed: onRemove, icon: Icon(Icons.favorite, color: AppTheme.coral))));
}
