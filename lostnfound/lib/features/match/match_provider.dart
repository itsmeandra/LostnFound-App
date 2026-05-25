import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/report/data/item_model.dart';
import '../../../../main.dart';

//───── Model match ─────
class MatchModel {
  final String id;
  final String lostItemId;
  final String foundItemId;
  final double similarityScore; // 0.0 – 1.0
  final String status;          // suggested | confirmed | dismissed
  final DateTime createdAt;

  // Join data
  final ItemModel? lostItem;
  final ItemModel? foundItem;

  const MatchModel({
    required this.id,
    required this.lostItemId,
    required this.foundItemId,
    required this.similarityScore,
    required this.status,
    required this.createdAt,
    this.lostItem,
    this.foundItem,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    ItemModel? lostItem;
    ItemModel? foundItem;

    if (json['lost_item'] != null) {
      lostItem = ItemModel.fromJson(
          json['lost_item'] as Map<String, dynamic>);
    }
    if (json['found_item'] != null) {
      foundItem = ItemModel.fromJson(
          json['found_item'] as Map<String, dynamic>);
    }

    return MatchModel(
      id:               json['id'] as String,
      lostItemId:       json['lost_item_id'] as String,
      foundItemId:      json['found_item_id'] as String,
      similarityScore:  (json['similarity_score'] as num).toDouble(),
      status:           json['status'] as String? ?? 'suggested',
      createdAt:        DateTime.parse(json['created_at'] as String),
      lostItem:         lostItem,
      foundItem:        foundItem,
    );
  }

  /// Skor dalam persen, misal 0.75 → 75
  int get scorePercent => (similarityScore * 100).round();

  bool get isSuggested  => status == 'suggested';
  bool get isConfirmed  => status == 'confirmed';
  bool get isDismissed  => status == 'dismissed';
}

//───── Provider: match untuk satu item ─────
// Dipakai di ItemDetailScreen untuk tampilkan saran cocok.
final matchesForItemProvider =
    FutureProvider.autoDispose.family<List<MatchModel>, String>(
        (ref, itemId) async {
  // Query matches di mana item ini adalah lost_item ATAU found_item
  final resp = await supabase
      .from(AppConstants.tableMatches)
      .select('''
        *,
        lost_item:lost_item_id (*),
        found_item:found_item_id (*)
      ''')
      .or('lost_item_id.eq.$itemId,found_item_id.eq.$itemId')
      .eq('status', 'suggested')
      .order('similarity_score', ascending: false)
      .limit(5);

  return (resp as List<dynamic>)
      .map((j) => MatchModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ── Provider: semua match milik user ─────────────────────────
// Dipakai di halaman "Laporan Saya" untuk menampilkan badge
// "Ada kemungkinan cocok".
final myMatchesProvider =
    FutureProvider.autoDispose<List<MatchModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // Ambil semua item user dulu
  final itemsResp = await supabase
      .from('items')
      .select('id')
      .eq('reporter_id', user.id);

  final itemIds = (itemsResp as List<dynamic>)
      .map((j) => (j as Map<String, dynamic>)['id'] as String)
      .toList();

  if (itemIds.isEmpty) return [];

  // Query matches yang melibatkan item user
  final matchResp = await supabase
      .from(AppConstants.tableMatches)
      .select('''
        *,
        lost_item:lost_item_id (
          id, name, category, location, photo_urls, status, type
        ),
        found_item:found_item_id (
          id, name, category, location, photo_urls, status, type
        )
      ''')
      .or('lost_item_id.in.(${itemIds.join(",")}),found_item_id.in.(${itemIds.join(",")})')
      .eq('status', 'suggested')
      .order('similarity_score', ascending: false);

  return (matchResp as List<dynamic>)
      .map((j) => MatchModel.fromJson(j as Map<String, dynamic>))
      .toList();
});