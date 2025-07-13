import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_moment/data/models/product.dart';
import 'package:pet_moment/presentation/pages/shop/shopDetail.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  _ShoppingPageState createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  Future<List<Product>> _fetchProducts() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Shopping').get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // 이미지 URL이 없을 경우 사용할 기본 이미지 URL
      String imageUrl = data['image'] ?? 'assets/Album_de.png';

      return Product(
        category: Category.values.firstWhere(
          (e) => e.toString() == 'Category.${data['category']}',
          orElse: () => Category.all,
        ),
        id: data['id'].toString(),
        name: data['name'] as String,
        price: data['price'] as int,
        image: imageUrl,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '주문하기',
          style: TextStyle(
            color: Color(0xFFE94A39),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Color(0xFFE94A39)),
            width: double.infinity,
            height: 40,
            child: const Center(
              child: Text(
                '3만원 이상 무료배송',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products available'));
                }

                final products = snapshot.data!;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 9.0 / 12.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShopDetail(productId: product.id),
                              ),
                            );
                          },
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: product.image.isNotEmpty &&
                                    product.image.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: product.image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Image.asset('assets/Album_de.png',
                                            fit: BoxFit.cover),
                                  )
                                : Image.asset(
                                    'assets/Album_de.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${NumberFormat("#,###", "ko_KR").format(product.price)}원',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
