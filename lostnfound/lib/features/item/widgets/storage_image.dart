import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ── Widget gambar tunggal dari Storage ───────────────────────
class StorageImage extends StatelessWidget {
  final String url; // Signed URL atau URL publik
  final double? width;
  final double? height;
  final BoxFit fit;

  const StorageImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder(context);
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.grey.shade200),
      ),
      errorWidget: (_, __, ___) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
      ),
    );
  }
}

// ── Carousel viewer untuk halaman detail ─────────────────────
// Menampilkan beberapa foto dalam PageView dengan indicator dot.
class PhotoCarouselViewer extends StatefulWidget {
  final List<String> photoUrls;
  final double height;

  const PhotoCarouselViewer({
    super.key,
    required this.photoUrls,
    this.height = 280,
  });

  @override
  State<PhotoCarouselViewer> createState() => _PhotoCarouselViewerState();
}

class _PhotoCarouselViewerState extends State<PhotoCarouselViewer> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // PageView foto
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.photoUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullscreen(context, i),
              child: StorageImage(
                url: widget.photoUrls[i],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Indicator dot (jika lebih dari 1 foto)
        if (widget.photoUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photoUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),

        // Counter badge (e.g. "2/5")
        if (widget.photoUrls.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${widget.photoUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Buka foto fullscreen ──────────────────────────────────
  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenPhotoViewer(
          urls: widget.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ── Fullscreen photo viewer ────────────────────────────────────
class _FullscreenPhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullscreenPhotoViewer({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<_FullscreenPhotoViewer> {
  late int _current;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          // Pinch-to-zoom
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
