import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_moment/presentation/pages/shop/AlbumSheet.dart';

class ShopDetail extends StatelessWidget {
  final String productId;

  const ShopDetail({super.key, required this.productId});

  Future<Map<String, dynamic>?> _fetchProductDetails(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Shopping')
          .doc(productId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchProductDetails(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('상품 정보를 불러올 수 없습니다.'));
          }

          final productData = snapshot.data!;
          final imageUrl = productData['image'] ?? '';
          final name = productData['name'] ?? '이름 없음';
          final subtext = productData['subtext'] ?? '설명이 없습니다.';
          final price = productData['price'] ?? 0;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        child:
                            imageUrl.isNotEmpty && imageUrl.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Center(child: Text('이미지 로드 실패')),
                                  )
                                : Image.asset(
                                    'assets/Album_de.png',
                                    fit: BoxFit.cover,
                                  ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          subtext,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '${NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0).format(price)}원',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                        child: Divider(
                          indent: 15,
                          endIndent: 15,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productData['memo'] ?? '제목 없음',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (productData['explain'] != null)
                              ...List<Widget>.generate(
                                (productData['explain'] as List).length,
                                (index) {
                                  final explanation =
                                      productData['explain'][index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      '• $explanation',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      builder: (context) {
                        return FractionallySizedBox(
                          heightFactor: 0.7,
                          child: AlbumSelectionSheet(
                            productName: name,
                            productImage: imageUrl,
                            price: price,
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94A39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    '구매하기',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
