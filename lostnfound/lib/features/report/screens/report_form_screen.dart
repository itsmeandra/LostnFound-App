import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  TimeOfDay _itemTime = TimeOfDay.now();

  // State untuk peta
  LatLng _currentLocation = const LatLng(
    -0.02639334884986339,
    109.34275565105214,
  );

  // Fungsi Reverse Geocoding
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String address =
            '${place.street}, ${place.subLocality}, ${place.locality}';

        address = address.replaceAll(RegExp(r', null|null, |null'), '').trim();

        // Otomatis isi kolom teks lokasi
        setState(() {
          _locationCtrl.text = address;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil alamat: $e");
    }
  }

  final Color _bgColor = const Color(0xFFFAF9FB);
  final Color _greenBadge = const Color(0xFF6CF8BB);

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

    final combinedDateTime = DateTime(
      _itemDate.year,
      _itemDate.month,
      _itemDate.day,
      _itemTime.hour,
      _itemTime.minute,
    );

    await ref
        .read(reportFormProvider.notifier)
        .submitReport(
          type: _type,
          name: _nameCtrl.text,
          category: _category,
          location: _locationCtrl.text,
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
          description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
          distinctiveFeatures: _featCtrl.text.isNotEmpty
              ? _featCtrl.text
              : null,
          itemDate: combinedDateTime,
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _itemTime,
    );
    if (picked != null) setState(() => _itemTime = picked);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // Helper Dekorasi Input
  InputDecoration _inputDecoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black87),
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //───── Header Laporan ─────
              const Text(
                'Buat Laporan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help our community reconnect lost items with their owners. Please provide as much detail as possible.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              //───── CARD 1: Item Basics ─────
              _buildStepCard(
                step: 'Step 2',
                title: 'Item Basics',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //───── Toggle: Hilang / Temuan ─────
                    _SectionLabel('Jenis Laporan'),
                    const SizedBox(height: 4),
                    Container(
                      // height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _TypeToggle(
                        selected: _type,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    //───── Nama Barang ─────
                    _SectionLabel('Nama Barang *'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        hint: 'Contoh: Dompet coklat, HP Samsung, Kunci motor',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama barang wajib diisi';
                        }
                        if (v.trim().length < 3) return 'Nama terlalu pendek';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    //───── Kategori ─────
                    _SectionLabel('Kategori *'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: _inputDecoration(
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CARD 2: When & Where
              _buildStepCard(
                step: 'Step 2',
                title: 'When & Where',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //───── Tanggal ─────
                    _SectionLabel(
                      'Tanggal ${_type == 'lost' ? 'Hilang' : 'Ditemukan'} *',
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(_itemDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    //───── Waktu ─────
                    _SectionLabel('Approximate Time *'),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _pickTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration:
                              _inputDecoration(
                                hint: '--:-- --',
                                prefixIcon: Icon(Icons.access_time_sharp),
                              ).copyWith(
                                hintText: _itemTime.format(context),
                                hintStyle: const TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    //───── Lokasi ─────
                    _SectionLabel('Lokasi *'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _locationCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Kantin Gedung A, Parkiran depan kampus',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Lokasi wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),

                    //───── Maps ─────
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip
                          .hardEdge, // Agar peta tidak bocor keluar sudut melengkung
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _currentLocation,
                              initialZoom: 16.0,
                              // Ambil alamat SETELAH peta selesai digeser
                              onMapEvent: (MapEvent event) {
                                if (event is MapEventMoveEnd) {
                                  _getAddressFromLatLng(
                                    event.camera.center.latitude,
                                    event.camera.center.longitude,
                                  );
                                }
                              },
                              // Update koordinat SECARA REALTIME saat digeser
                              onPositionChanged: (position, hasGesture) {
                                if (hasGesture && position.center != null) {
                                  setState(() {
                                    _currentLocation = position.center!;
                                  });
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.keandy.lostnfound',
                              ),
                            ],
                          ),
                          // Pin statis di tengah layar
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 35.0),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                          // Label instruksi
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Geser peta untuk menentukan titik',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CARD 2: When & Where
              _buildStepCard(
                step: 'Step 3',
                title: 'Visuals & Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        color: theme.colorScheme.secondaryContainer.withOpacity(
                          0.4,
                        ),
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

                    const SizedBox(height: 16),

                    //───── Foto ─────
                    const PhotoPickerWidget(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _type == 'lost'
                                ? 'Kirim Laporan Kehilangan'
                                : 'Kirim Laporan Temuan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
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
      ),
    );
  }

  // ── Widget Helper untuk Card Step ──
  Widget _buildStepCard({
    required String step,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _greenBadge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

//───── Widget helper ─────
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(opsional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

//───── Toggle Hilang / Temuan ─────
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
            // icon: Icons.search_off_outlined,
            color: AppTheme.statusPending,
            selected: selected == 'lost',
            onTap: () => onChanged('lost'),
          ),
        ),
        // const SizedBox(width: 10),
        Expanded(
          child: _ToggleOption(
            value: 'found',
            label: 'Barang Temuan',
            // icon: Icons.search_outlined,
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
  // final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.value,
    required this.label,
    // required this.icon,
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
            // Icon(icon, color: selected ? color : Colors.grey, size: 24),
            // const SizedBox(height: 6),
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
