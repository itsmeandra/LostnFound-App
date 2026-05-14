import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/features/report/data/item_model.dart';
import 'package:lostnfound/main.dart';

// Model gabungan item + info pelapor
class ItemDetail {
  final ItemModel item;
  final String reporterName;

  const ItemDetail({required this.item, required this.reporterName});
}

// FutureProvider.family: satu provider instance per item ID
final itemDetailProvider =
    FutureProvider.autoDispose.family<ItemDetail, String>((ref, itemId) async {
  // Query items_public — tidak expose distinctive_features ke user biasa
  final itemResp = await supabase
      .from('items_public')
      .select()
      .eq('id', itemId)
      .single();

  final item = ItemModel.fromJson(itemResp as Map<String, dynamic>);

  // Fetch nama pelapor — RLS hanya izinkan full_name
  String reporterName = 'Pengguna';
  try {
    final profileResp = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', item.reporterId)
        .single();
    reporterName =
        (profileResp as Map<String, dynamic>)['full_name'] as String? ??
            'Pengguna';
  } catch (_) {}

  return ItemDetail(item: item, reporterName: reporterName);
});