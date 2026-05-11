import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/report/data/report_provider.dart';
import 'package:lostnfound/features/report/widgets/photo_picker_widget.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _featCtrl = TextEditingController(); // distinctive_features

  // State lokal form
  String _type = 'lost'; // 'lost' atau 'found'
  String _category = 'other';
  DateTime _itemDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _featCtrl.dispose();
    super.dispose();
  }

  //───── Submit ─────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final photos = ref.read(reportFormProvider).selectedPhotos;
    if (photos.isEmpty) {
      _showSnack('Tambahkan minimal 1 foto barang.', isError: true);
      return;
    }

    await ref
        .read(reportFormProvider.notifier)
        .submitReport(
          type: _type,
          name: _nameCtrl.text,
          category: _category,
          location: _locationCtrl.text,
          description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
          distinctiveFeatures: _featCtrl.text.isNotEmpty
              ? _featCtrl.text
              : null,
          itemDate: _itemDate,
        );
  }

  //───── Date Picker ─────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _itemDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      helpText: 'Tanggal kejadian',
    );
    if (picked != null) setState(() => _itemDate = picked);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reportFormProvider);
    final theme = Theme.of(context);

    //───── Listener: sukses atau error ─────
    ref.listen(reportFormProvider, (prev, next) {
      if (next.isSuccess) {
        _showSnack('Laporan berhasil dikirim! Menunggu verifikasi admin.');
        ref.read(reportFormProvider.notifier).reset();
        context.pop();
      } else if (next.error != null && prev?.error != next.error) {
        _showSnack(next.error!, isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          // Tombol submit di AppBar (alternatif dari tombol bawah)
          if (formState.isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            //───── Toggle: Hilang / Temuan ─────
            _SectionLabel('Jenis Laporan'),
            const SizedBox(height: 8),
            _TypeToggle(
              selected: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 20),

            //───── Nama Barang ─────
            _SectionLabel('Nama Barang *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: Dompet coklat, HP Samsung, Kunci motor',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Nama barang wajib diisi';
                if (v.trim().length < 3) return 'Nama terlalu pendek';
                return null;
              },
            ),
            const SizedBox(height: 16),

            //───── Kategori ─────
            _SectionLabel('Kategori *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.itemCategories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            //───── Lokasi ─────
            _SectionLabel('Lokasi *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: Kantin Gedung A, Parkiran depan kampus',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Lokasi wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 16),

            //───── Tanggal Kejadian ─────
            _SectionLabel(
              'Tanggal ${_type == 'lost' ? 'Hilang' : 'Ditemukan'} *',
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_itemDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            //───── Deskripsi ─────
            _SectionLabel('Deskripsi', optional: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Ceritakan ciri umum barang yang bisa dilihat semua orang...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 42),
                  child: Icon(Icons.description_outlined),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            //───── Ciri Khusus ─────
            _SectionLabel('Ciri Khusus / Rahasia', optional: true),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hanya kamu dan admin yang bisa melihat ini. '
                      'Dipakai untuk memverifikasi klaim. '
                      'Contoh: "Ada goresan di sudut kiri bawah" atau '
                      '"Stiker avatar di belakang".',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSecondaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _featCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ciri yang hanya diketahui pemilik asli...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(Icons.vpn_key_outlined),
                ),
              ),
            ),
            const SizedBox(height: 20),

            //───── Foto ─────
            const PhotoPickerWidget(),
            const SizedBox(height: 32),

            //───── Tombol Submit ─────
            ElevatedButton(
              onPressed: formState.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'lost'
                    ? AppTheme
                          .statusPending // oranye untuk laporan hilang
                    : AppTheme.statusPublished, // hijau untuk temuan
                foregroundColor: Colors.white,
              ),
              child: formState.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Mengupload foto & menyimpan...'),
                      ],
                    )
                  : Text(
                      _type == 'lost'
                          ? 'Kirim Laporan Kehilangan'
                          : 'Kirim Laporan Temuan',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),

            const SizedBox(height: 12),
            Text(
              'Laporanmu akan ditinjau oleh admin sebelum dipublikasikan.\n'
              'Proses verifikasi biasanya kurang dari 24 jam.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget helper ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const _SectionLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(opsional)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Toggle Hilang / Temuan ─────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleOption(
            value: 'lost',
            label: 'Barang Hilang',
            icon: Icons.search_off_outlined,
            color: AppTheme.statusPending,
            selected: selected == 'lost',
            onTap: () => onChanged('lost'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleOption(
            value: 'found',
            label: 'Barang Temuan',
            icon: Icons.search_outlined,
            color: AppTheme.statusPublished,
            selected: selected == 'found',
            onTap: () => onChanged('found'),
          ),
        ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
