import 'package:flutter/material.dart';

class ReviewCard extends StatefulWidget {
  final String reviewId;
  final String runnerName;
  final String eventName;
  final String reviewText;
  final double rating;
  final bool isOwner; // Apakah user ini pemilik review
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    Key? key,
    required this.reviewId,
    required this.runnerName,
    required this.eventName,
    required this.reviewText,
    required this.rating,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _showMenu = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleMenu() {
    if (_showMenu) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showMenu = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showMenu = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: 192,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(size.width - 192 - 16, 40),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        InkWell(
                          onTap: () {
                            _removeOverlay();
                            widget.onEdit?.call();
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Colors.blue[500],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Divider
                        const Divider(
                          height: 1,
                          color: Color(0xFFF3F4F6),
                        ),
                        // Delete Button
                        InkWell(
                          onTap: () {
                            _removeOverlay();
                            widget.onDelete?.call();
                          },
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Stack(
          children: [
            Column(
              children: [
                // Runner Name
                Text(
                  widget.runnerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Event Name
                Text(
                  widget.eventName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Review Text
                Text(
                  widget.reviewText.isEmpty 
                      ? 'No comment' 
                      : widget.reviewText,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.reviewText.isEmpty 
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFA3E635),
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.rating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Text(
                      '/5.0 rating',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Three Dots Menu (Only for owner)
            if (widget.isOwner)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: _showMenu 
                        ? const Color(0xFF4B5563) 
                        : const Color(0xFF9CA3AF),
                  ),
                  onPressed: _toggleMenu,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Contoh penggunaan:
// 
// ReviewCard(
//   reviewId: 'review_123',
//   runnerName: 'Leticia Kutch',
//   eventName: 'Participant Summer Marathon',
//   reviewText: 'Lorem ipsum dolor sit amet pretium consectetur adipiscing elit. Lorem consectetur adipiscing elit. Pretium consectetur adipiscing elit. Lorem consectetur adipiscing elit.',
//   rating: 4.75,
//   isOwner: true, // set true jika user adalah pemilik review
//   onEdit: () {
//     // Handle edit
//     showDialog(
//       context: context,
//       builder: (context) => ReviewModal(
//         eventName: 'Participant Summer Marathon',
//         eventId: 'event_123',
//         reviewId: 'review_123',
//         initialRating: 5,
//         initialReview: 'Great event!',
//         onSubmit: (rating, reviewText) {
//           // Update review
//         },
//       ),
//     );
//   },
//   onDelete: () {
//     // Show confirmation dialog
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Review'),
//         content: const Text('Are you sure you want to delete this review?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               // Delete review
//               Navigator.pop(context);
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   },
// )