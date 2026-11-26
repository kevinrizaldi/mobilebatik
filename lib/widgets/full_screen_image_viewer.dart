import 'package:flutter/material.dart';

/// Full-screen image viewer with pinch-to-zoom and swipe to dismiss.
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (_, __, ___) => FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // PageView for swipe between images
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              final heroTag = widget.heroTagPrefix != null
                  ? '${widget.heroTagPrefix}_$index'
                  : 'review_image_$index';

              return Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top: Close button + counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom: Swipe down hint
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Geser ke bawah untuk menutup',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail widget yang bisa di-tap untuk buka full-screen
class ReviewPhotoThumbnail extends StatelessWidget {
  final String imageUrl;
  final int index;
  final List<String> allImageUrls;
  final String? heroTagPrefix;
  final double size;
  final BorderRadius borderRadius;

  const ReviewPhotoThumbnail({
    super.key,
    required this.imageUrl,
    required this.index,
    required this.allImageUrls,
    this.heroTagPrefix,
    this.size = 54,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_$index'
        : 'review_image_$index';

    return GestureDetector(
      onTap: () => FullScreenImageViewer.show(
        context,
        imageUrls: allImageUrls,
        initialIndex: index,
        heroTagPrefix: heroTagPrefix,
      ),
      child: Hero(
        tag: heroTag,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: size,
                    height: size,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: size * 0.45,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}