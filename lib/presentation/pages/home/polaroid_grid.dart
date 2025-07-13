import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_moment/presentation/pages/home/polaroid_detail.dart';
import 'package:shimmer/shimmer.dart';

class PolaroidGrid extends StatefulWidget {
  final String userId;
  final String albumId;
  final Future<void> Function()? onDelete;

  const PolaroidGrid({
    Key? key,
    required this.userId,
    required this.albumId,
    this.onDelete,
  }) : super(key: key);

  @override
  _PolaroidGridState createState() => _PolaroidGridState();
}

class _PolaroidGridState extends State<PolaroidGrid> {
  int currentPage = 0;
  static const int itemsPerPage = 4;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('albums')
          .doc(widget.albumId)
          .collection('polaroid')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('추억을 담을 첫 사진을 추가해보세요'));
        }
        final allPolaroids = snapshot.data!.docs;
        final totalPages = (allPolaroids.length / itemsPerPage).ceil();
        final startIndex = currentPage * itemsPerPage;
        final endIndex =
            math.min(startIndex + itemsPerPage, allPolaroids.length);
        final currentPolaroids = allPolaroids.sublist(startIndex, endIndex);
        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.71,
                    ),
                    itemCount: currentPolaroids.length,
                    itemBuilder: (context, index) {
                      final polaroid = currentPolaroids[index];
                      final imageUrl = polaroid['imageUrl'] ?? '';
                      final text =
                          (polaroid['text'] ?? '').replaceAll("\\n", "\n");
                      final timestamp = polaroid['timestamp'] != null
                          ? (polaroid['timestamp'] as Timestamp).toDate()
                          : DateTime.now();
                      return GestureDetector(
                        onTap: () => _showPolaroidDetail(polaroid),
                        child: Card(
                          color: Colors.white,
                          elevation: 4,
                          shape: const RoundedRectangleBorder(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: AspectRatio(
                                  aspectRatio: 0.9,
                                  child: ClipRRect(
                                    child: imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                  color: Colors.white),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error,
                                                        color: Colors.red),
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image,
                                                size: 50),
                                          ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'HS유지체'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 10, 5),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    "${timestamp.year}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.day.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                        fontSize: 10, fontFamily: 'HS유지체'),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: currentPage > 0
                            ? () => setState(() => currentPage--)
                            : null,
                        color: currentPage > 0
                            ? Colors.black
                            : Colors.grey.shade300,
                      ),
                      Text(
                        '${currentPage + 1} / $totalPages',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: currentPage < totalPages - 1
                            ? () => setState(() => currentPage++)
                            : null,
                        color: currentPage < totalPages - 1
                            ? Colors.black
                            : Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPolaroidDetail(DocumentSnapshot polaroid) async {
    // showGeneralDialog 에서 true 가 반환되면 삭제가 발생한 것
    final bool? deleted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // 상세뷰 터치 막기
                child: PolaroidDetail(
                  userId: widget.userId,
                  albumId: widget.albumId,
                  polaroidId: polaroid.id,
                  isCalendarView: false,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    // 삭제가 true 로 리턴되었고, 부모 콜백이 있다면 실행
    if (deleted == true && widget.onDelete != null) {
      await widget.onDelete!();
    }
  }
}
