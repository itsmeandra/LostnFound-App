import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/home/widgets/notification_badge.dart';
import 'package:lostnfound/features/report/data/report_provider.dart';

const _kStatusOrder = ['pending', 'published', 'claimed', 'completed', 'returned'];

String _statusLabel(String s) => switch (s) {
  'pending' => 'Menunggu',
  'published' => 'Dipublikasi',
  'claimed' => 'Diklaim',
  'completed' => 'Selesai',
  'rejected' => 'Ditolak',
  'returned' => 'Dikembalikan',
  _ => s,
};

Color _statusColor(String s) => switch (s) {
  'pending' => const Color(0xFFF59E0B),
  'published' => const Color(0xFF10B981),
  'claimed' => const Color(0xFF3B82F6),
  'completed' => const Color(0xFF059669),
  'rejected' => const Color(0xFFEF4444),
  'returned' => const Color(0xFF232F72),
  _ => const Color(0xFF94A3B8),
};

IconData _statusIcon(String s) => switch (s) {
  'pending' => Icons.hourglass_empty_rounded,
  'published' => Icons.visibility_outlined,
  'claimed' => Icons.handshake_outlined,
  'completed' => Icons.check_circle_outline_rounded,
  'rejected' => Icons.cancel_outlined,
  'returned' => Icons.keyboard_return_outlined,
  _ => Icons.circle_outlined,
};

// ── Main screen ───────────────────────────────────────────────────────────────

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Lacak Laporan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [const NotificationBadge()],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF1F5F9)),
        ),
      ),
      body: reportsAsync.when(
        loading: () => const _ShimmerList(),
        error: (_, __) => const _ErrorView(),
        data: (reports) {
          if (reports.isEmpty) return const _EmptyView();

          final pending = reports.where((r) => r.status == 'pending').length;
          final published = reports
              .where((r) => r.status == 'published')
              .length;
          final completed = reports
              .where((r) => r.status == 'completed')
              .length;
          final rejected = reports.where((r) => r.status == 'rejected').length;
          final returned = reports
              .where((r) => r.status == 'returned')
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              // ── Summary strip ──────────────────────────────────
              _SummaryStrip(
                pending: pending,
                published: published,
                completed: completed,
                rejected: rejected,
                returned: returned,
              ),
              const SizedBox(height: 20),

              // ── Recent header ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Laporan Terbaru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppConstants.routeMyReports),
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Report cards ───────────────────────────────────
              ...reports
                  .take(5)
                  .map(
                    (r) => _ReportCard(
                      id: r.id ?? '',
                      name: r.name,
                      location: r.location,
                      type: r.type,
                      status: r.status,
                      photoUrl: r.photoUrls.isNotEmpty
                          ? r.photoUrls.first
                          : null,
                      onTap: () => context.push('/item/${r.id}'),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary strip ─────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int pending, published, completed, rejected, returned;

  const _SummaryStrip({
    required this.pending,
    required this.published,
    required this.completed,
    required this.rejected,
    required this.returned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryTile(
            count: pending,
            label: 'Menunggu',
            color: const Color(0xFFF59E0B),
          ),
          _SummaryDivider(),
          _SummaryTile(
            count: published,
            label: 'Dipublikasi',
            color: const Color(0xFF10B981),
          ),
          _SummaryDivider(),
          _SummaryTile(
            count: returned,
            label: 'Dikembalikan',
            color: const Color(0xFF059669),
          ),
          _SummaryDivider(),
          _SummaryTile(
            count: rejected,
            label: 'Ditolak',
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryTile({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFF1F5F9));
}

// ── Report card with vertical stepper ────────────────────────────────────────

class _ReportCard extends StatefulWidget {
  final String id, name, location, type, status;
  final String? photoUrl;
  final VoidCallback onTap;

  const _ReportCard({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.status,
    this.photoUrl,
    required this.onTap,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isRejected = widget.status == 'rejected';
    final color = _statusColor(widget.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ───────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  // Type badge
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: color.withOpacity(0.08),
                      child:
                          widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                          ? Image.network(
                              widget.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 20,
                                      color: color,
                                    ),
                                  ),
                            )
                          : Center(
                              // Jika tidak ada foto sama sekali, kembalikan ke emoji bawaan
                              child: Text(
                                widget.type == 'lost' ? '🔴' : '🟢',
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel(widget.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stepper (expanded) ───────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: [
                      Container(height: 1, color: const Color(0xFFF1F5F9)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: isRejected
                            ? _RejectedBanner()
                            : _StatusStepper(currentStatus: widget.status),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: _OutlineButton(
                          label: 'Lihat Detail',
                          icon: Icons.arrow_forward_rounded,
                          onTap: widget.onTap,
                          compact: true,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Vertical stepper ──────────────────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final String currentStatus;

  const _StatusStepper({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _kStatusOrder.indexOf(currentStatus);

    return Column(
      children: _kStatusOrder.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isDone = currentIndex > index;
        final isActive = currentIndex == index;
        final isLast = index == _kStatusOrder.length - 1;
        final color = isActive
            ? _statusColor(currentStatus)
            : isDone
            ? const Color(0xFF10B981)
            : const Color(0xFFE2E8F0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + line column
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  // Dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(
                        isActive || isDone ? 0.12 : 0.06,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: isActive ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            )
                          : Icon(
                              _statusIcon(status),
                              size: 12,
                              color: isActive ? color : const Color(0xFFCBD5E1),
                            ),
                    ),
                  ),
                  // Connector line
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF10B981).withOpacity(0.35)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Label
            Padding(
              padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF0F172A)
                          : isDone
                          ? const Color(0xFF10B981)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Status saat ini',
                        style: TextStyle(
                          fontSize: 10,
                          color: _statusColor(currentStatus).withOpacity(0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Rejected banner ───────────────────────────────────────────────────────────

class _RejectedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan Ditolak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Laporan ini tidak memenuhi kriteria verifikasi. Lihat detail untuk informasi lebih lanjut.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable outline button ───────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 40 : 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF0FDF4),
          side: const BorderSide(color: Color(0xFFD1FAE5), width: 1.5),
          backgroundColor: const Color(0xFF141A28),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada laporan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap tombol "Lapor" di Beranda\nuntuk membuat laporan pertamamu.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 28,
                color: Color(0xFFFCA5A5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Periksa koneksi internetmu\ndan coba lagi.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer loading list ──────────────────────────────────────────────────────

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bone(double w, double h, {double radius = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
            stops: [
              (_anim.value - 0.5).clamp(0.0, 1.0),
              (_anim.value).clamp(0.0, 1.0),
              (_anim.value + 0.5).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Summary strip skeleton
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (_) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bone(28, 20, radius: 4),
                  const SizedBox(height: 6),
                  _bone(40, 10, radius: 4),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _bone(double.infinity, 48, radius: 12),
        const SizedBox(height: 28),
        _bone(120, 14, radius: 4),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _bone(40, 40, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bone(140, 12, radius: 4),
                      const SizedBox(height: 6),
                      _bone(90, 10, radius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _bone(60, 24, radius: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
