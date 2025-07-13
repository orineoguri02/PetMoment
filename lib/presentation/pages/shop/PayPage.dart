import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_moment/presentation/pages/shop/AddressSave.dart';
import 'package:pet_moment/presentation/pages/shop/finishPage.dart';

class PayPage extends StatefulWidget {
  final int totalPrice;
  final int quantity;
  final String productName;
  final String productImage;

  const PayPage({
    super.key,
    required this.totalPrice,
    required this.quantity,
    required this.productName,
    required this.productImage,
  });

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> savedAddresses = [];
  int? defaultAddressIndex;
  final int shippingFee = 3000; // 배송비 3000원

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        savedAddresses =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        defaultAddressIndex = savedAddresses
            .indexWhere((address) => address['isDefault'] == true);
        if (defaultAddressIndex == -1) defaultAddressIndex = null;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      showCustomSnackBar('주소 목록을 불러오는데 실패했습니다.');
    }
  }

  void showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 총 상품금액은 배송비(3000원) 제외한 값으로 표시됨
    final String formattedProductPrice = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '',
      decimalDigits: 0,
    ).format(widget.totalPrice - shippingFee);

    // 총 주문금액은 widget.totalPrice 그대로
    final String formattedOrderPrice = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '',
      decimalDigits: 0,
    ).format(widget.totalPrice);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '주문/결제',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주문상품 정보 영역
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주문상품 총 ${widget.quantity}개',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProductInfo(),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.grey[100],
                    height: 8,
                  ),
                  _buildShippingInfo(),
                  Container(
                    color: Colors.grey[100],
                    height: 8,
                  ),
                  _buildPaymentMethod(),
                ],
              ),
            ),
          ),
          // 하단 결제 금액 및 구매하기 버튼 영역
          _buildBottomBar(formattedProductPrice, formattedOrderPrice),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: widget.productImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              )),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.productName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 배송지 제목과 변경하기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '배송지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedAddressesScreen(),
                    ),
                  );
                  if (result != null) {
                    _loadAddresses(); // 배송지 변경 후 목록 새로고침
                  }
                },
                child: Text(
                  '변경하기',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (defaultAddressIndex != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savedAddresses[defaultAddressIndex!]['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  savedAddresses[defaultAddressIndex!]['phone'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${savedAddresses[defaultAddressIndex!]['mainAddress']} ${savedAddresses[defaultAddressIndex!]['detailAddress']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            )
          else if (savedAddresses.isNotEmpty)
            Text(
              '배송지를 선택해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            )
          else
            Text(
              '등록된 배송지가 없습니다. 배송지를 추가해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: '배송 시 요청사항을 선택해주세요.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '결제수단',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Radio(
                value: true,
                groupValue: true,
                onChanged: null,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              const Text('무통장입금'),
              const SizedBox(width: 20),
              Text(
                '123451234 농협은행',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '위의 계좌로 총결제 금액의 입금자를 적어주세요.',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '위의 계좌로 송금할 본인의 전화번호를 작성해주세요.',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      String formattedProductPrice, String formattedOrderPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 총 상품금액 (배송비 제외)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 상품금액'),
              Text('$formattedProductPrice원'),
            ],
          ),
          const SizedBox(height: 8),
          // 배송비 (표시만 함)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('배송비'),
              Text('${NumberFormat.currency(
                locale: 'ko_KR',
                symbol: '',
                decimalDigits: 0,
              ).format(shippingFee)}원'),
            ],
          ),
          const SizedBox(height: 8),
          // 총 주문금액 (배송비 포함; widget.totalPrice 그대로)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 주문금액',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$formattedOrderPrice원',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 구매하기 버튼: 텍스트는 총 주문금액 표시, Finishpage에는 widget.totalPrice 전달
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Finishpage(
                      totalPrice: widget.totalPrice,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '$formattedOrderPrice원 결제하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
