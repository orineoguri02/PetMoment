import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_moment/presentation/pages/shop/PayPage.dart';

class AlbumSelectionSheet extends StatefulWidget {
  final String productName;
  final String productImage;
  final int price;

  const AlbumSelectionSheet({
    super.key,
    required this.productName,
    required this.productImage,
    required this.price,
  });

  @override
  State<AlbumSelectionSheet> createState() => _AlbumSelectionSheetState();
}

class _AlbumSelectionSheetState extends State<AlbumSelectionSheet> {
  List<Map<String, dynamic>> _items = [
    {
      'headerValue': '앨범 선택하기',
      'albums': [],
      'isExpanded': false,
    },
  ];
  List<Map<String, dynamic>> selectedAlbums = [];
  Map<String, int> quantities = {};
  final int shippingFee = 3000;

  @override
  void initState() {
    super.initState();
    _loadUserAlbums();
  }

  // Firestore에서 현재 로그인한 유저의 albums 서브컬렉션을 가져오는 함수
  Future<void> _loadUserAlbums() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 로그인한 유저가 없을 경우, 기본값을 그대로 유지합니다.
      return;
    }

    // 예시: "users" 컬렉션 아래 유저 UID 문서의 "albums" 서브컬렉션에서 가져옵니다.
    QuerySnapshot albumSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('albums')
        .get();

    // 각 문서에서 albumName 필드를 가져와 리스트로 변환 (금액은 그대로 widget.price)
    List<Map<String, dynamic>> albumList = albumSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      String albumName = data['albumName'] ?? '앨범 이름 없음';
      return {
        'name': albumName,
        'price': widget.price,
      };
    }).toList();

    setState(() {
      _items = [
        {
          'headerValue': '앨범 선택하기',
          'albums': albumList,
          'isExpanded': false,
        },
      ];
    });
  }

  int getTotalPrice() {
    return selectedAlbums.fold<int>(0, (sum, album) {
      return sum + ((album['price'] as int) * (quantities[album['name']] ?? 1));
    });
  }

  int getTotalQuantity() {
    return quantities.values.fold<int>(0, (sum, quantity) => sum + quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 제목 및 닫기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '옵션 선택하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      expansionTileTheme: const ExpansionTileThemeData(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    child: ExpansionPanelList(
                      elevation: 1,
                      expandedHeaderPadding: EdgeInsets.zero,
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          _items[index]['isExpanded'] =
                              !_items[index]['isExpanded'];
                        });
                      },
                      children: _items.map<ExpansionPanel>((item) {
                        return ExpansionPanel(
                          backgroundColor: Colors.white,
                          headerBuilder:
                              (BuildContext context, bool isExpanded) {
                            return ListTile(
                              title: Text(
                                item['headerValue'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          body: Column(
                            children:
                                (item['albums'] as List).map<Widget>((album) {
                              return ListTile(
                                tileColor: Colors.white,
                                title: Text(album['name']),
                                subtitle: Text(
                                  '${NumberFormat('#,###').format(album['price'])}원',
                                ),
                                onTap: () {
                                  setState(() {
                                    if (selectedAlbums.contains(album)) {
                                      selectedAlbums.remove(album);
                                      quantities.remove(album['name']);
                                    } else {
                                      selectedAlbums.add(album);
                                      quantities[album['name']] = 1;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          isExpanded: item['isExpanded'],
                        );
                      }).toList(),
                    ),
                  ),
                  // 선택한 앨범들 리스트 출력
                  ...selectedAlbums
                      .map((album) => Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        album['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          selectedAlbums.remove(album);
                                          quantities.remove(album['name']);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed:
                                          (quantities[album['name']] ?? 1) > 1
                                              ? () {
                                                  setState(() {
                                                    quantities[album['name']] =
                                                        (quantities[album[
                                                                    'name']] ??
                                                                1) -
                                                            1;
                                                  });
                                                }
                                              : null,
                                    ),
                                    Text('${quantities[album['name']] ?? 1}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          quantities[album['name']] =
                                              (quantities[album['name']] ?? 1) +
                                                  1;
                                        });
                                      },
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${NumberFormat('#,###').format(album['price'] * (quantities[album['name']] ?? 1))}원',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
          if (selectedAlbums.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 ${getTotalQuantity()}개 상품'),
                Text(
                  '${NumberFormat('#,###').format(getTotalPrice())}원',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('배송비'),
                Text(
                  '${NumberFormat('#,###').format(shippingFee)}원',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '예상 결제금액',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${NumberFormat('#,###').format(getTotalPrice() + shippingFee)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final totalPrice = getTotalPrice() + shippingFee;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayPage(
                            totalPrice: totalPrice,
                            quantity: getTotalQuantity(),
                            productName: widget.productName,
                            productImage: widget.productImage,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94A39),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      '구매하기',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
