import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/report/data/item_model.dart';
import 'package:lostnfound/main.dart';
import 'dart:async';

//───── Filter state ─────
class ItemsFilter {
  final String category; // '' = semua kategori
  final String query; // '' = tidak ada search
  final int page; // 0-based

  const ItemsFilter({this.category = '', this.query = '', this.page = 0});

  ItemsFilter copyWith({String? category, String? query, int? page}) {
    return ItemsFilter(
      category: category ?? this.category,
      query: query ?? this.query,
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ItemsFilter &&
      other.category == category &&
      other.query == query &&
      other.page == page;

  @override
  int get hashCode => Object.hash(category, query, page);
}

//───── Filter provider ─────
// StateProvider sederhana untuk menyimpan filter aktif.
// Diubah dari HomeScreen saat user ketik search / pilih chip.
final itemsFilterProvider = StateProvider<ItemsFilter>(
  (ref) => const ItemsFilter(),
);

//───── Items list provider ─────
// FutureProvider yang bergantung pada itemsFilterProvider.
// Otomatis re-fetch saat filter berubah.
final itemsProvider = FutureProvider.autoDispose<List<ItemModel>>((ref) async {
  final filter = ref.watch(itemsFilterProvider);
  return _fetchItems(filter);
});

//───── Realtime subscription provider ─────
// Saat ada item baru di-publish admin, HomeScreen otomatis refresh.
final itemsRealtimeProvider = StreamProvider.autoDispose<List<ItemModel>>((
  ref,
) {
  final filter = ref.watch(itemsFilterProvider);

  // Controller untuk stream
  late final StreamController<List<ItemModel>> controller;

  // Fetch awal
  Future<void> fetchAndEmit() async {
    try {
      final items = await _fetchItems(filter);
      if (!controller.isClosed) controller.add(items);
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  // Subscription realtime ke tabel items (published saja)
  final subscription = supabase
      .from(AppConstants.tableItems)
      .stream(primaryKey: ['id'])
      .eq('status', 'published')
      .order('created_at', ascending: false)
      .limit(AppConstants.itemsPerPage)
      .map((data) => data.map((json) => ItemModel.fromJson(json)).toList());

  // Gabungkan fetch awal + realtime stream
  controller = StreamController<List<ItemModel>>();

  fetchAndEmit(); // fetch pertama kali

  // Subscribe ke realtime — saat ada perubahan, fetch ulang dengan filter
  final sub = subscription.listen((_) => fetchAndEmit());

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

//───── Helper: fetch dengan filter ─────
Future<List<ItemModel>> _fetchItems(ItemsFilter filter) async {
  final offset = filter.page * AppConstants.itemsPerPage;

  var query = supabase
      .from('items_public')
      .select()
      .eq('type', 'found'); // Hanya tampilkan barang TEMUAN di feed utama
  // .order('created_at', ascending: false)
  // .range(offset, offset + AppConstants.itemsPerPage - 1);

  // Filter kategori (jika dipilih)
  if (filter.category.isNotEmpty) {
    query = query.eq('category', filter.category) as dynamic;
  }

  // Search query (jika ada teks)
  // ilike: case-insensitive partial match
  // Untuk production: pertimbangkan pg_trgm similarity (Minggu 3)
  if (filter.query.isNotEmpty) {
    final q = '%${filter.query}%';
    // Filter OR: nama ATAU lokasi mengandung kata kunci
    query = query.or('name.ilike.$q,location.ilike.$q') as dynamic;
  }

  final response = await query
      .order('created_at', ascending: false)
      .range(offset, offset + AppConstants.itemsPerPage - 1);

  return (response as List<dynamic>)
      .map((json) => ItemModel.fromJson(json as Map<String, dynamic>))
      .toList();
}

//───── Storage URL helper ─────
Future<String> getSignedPhotoUrl(
  String storagePath, {
  int expiresIn = 3600,
}) async {
  return supabase.storage
      .from(AppConstants.itemPhotosBucket)
      .createSignedUrl(storagePath, expiresIn);
}
