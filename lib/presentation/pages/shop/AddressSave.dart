import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_moment/presentation/pages/shop/Address.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> savedAddresses = [];
  int? defaultAddressIndex;

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
        savedAddresses = snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();

        // 기본 배송지 찾기
        defaultAddressIndex = savedAddresses
            .indexWhere((address) => address['isDefault'] == true);
        if (defaultAddressIndex == -1) defaultAddressIndex = null;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      showCustomSnackBar('주소 목록을 불러오는데 실패했습니다.');
    }
  }

  Future<void> _navigateToAddAddress() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      showCustomSnackBar('로그인이 필요합니다.');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressManager(userId: userId),
      ),
    );

    if (result != null) {
      _loadAddresses(); // 주소 추가 후 목록 새로고침
    }
  }

  // 주소 선택 (이전의 삭제 함수를 대체)
  Future<void> _selectAddress(int index) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // 기존 기본 배송지가 있다면 해제
      if (defaultAddressIndex != null) {
        final currentDefaultId = savedAddresses[defaultAddressIndex!]['id'];
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(currentDefaultId)
            .update({'isDefault': false});
      }

      // 선택한 배송지를 기본 배송지로 설정
      final addressId = savedAddresses[index]['id'];
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .update({'isDefault': true});

      setState(() {
        defaultAddressIndex = index;
        // 기존 기본 배송지 해제
        if (defaultAddressIndex != null && defaultAddressIndex != index) {
          savedAddresses[defaultAddressIndex!]['isDefault'] = false;
        }
        // 새로운 기본 배송지 설정
        savedAddresses[index]['isDefault'] = true;
      });

      showCustomSnackBar('배송지가 선택되었습니다.');

      // PayPage로 돌아가기
      Navigator.pop(context, true);
    } catch (e) {
      print('Error selecting address: $e');
      showCustomSnackBar('배송지 선택에 실패했습니다.');
    }
  }

  void showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _setDefaultAddress(int index) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final addressesRef =
          _firestore.collection('users').doc(userId).collection('addresses');

      for (var address in savedAddresses) {
        if (address['isDefault'] == true) {
          batch.update(
            addressesRef.doc(address['id']),
            {'isDefault': false},
          );
        }
      }

      final newDefault = defaultAddressIndex != index;
      batch.update(
        addressesRef.doc(savedAddresses[index]['id']),
        {'isDefault': newDefault},
      );

      await batch.commit();

      setState(() {
        defaultAddressIndex = newDefault ? index : null;
        savedAddresses[index]['isDefault'] = newDefault;
      });

      showCustomSnackBar(
        newDefault ? '기본 배송지로 설정되었습니다.' : '기본 배송지가 해제되었습니다.',
      );
    } catch (e) {
      print('Error setting default address: $e');
      showCustomSnackBar('기본 배송지 설정에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          '배송지 설정',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 20,
            fontFamily: 'Pretendard Variable',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: ListView.builder(
        itemCount: savedAddresses.length + 1,
        itemBuilder: (context, index) {
          if (index == savedAddresses.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: _navigateToAddAddress,
                child: const Text(
                  '배송지 추가하기',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          }

          final address = savedAddresses[index];
          final isDefault = defaultAddressIndex == index;

          return ListTile(
            title: Row(
              children: [
                Text('${address['name']}'),
                if (isDefault)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0XFFE65951).withOpacity(0.0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '기본배송지',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 11,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address['mainAddress'] ?? '주소 정보 없음'),
                Text('${address['phone']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 수정 버튼: 기존 배송지 정보를 AddressManager 위젯에 전달하여 수정할 수 있도록 함
                TextButton(
                  onPressed: () async {
                    final userId = _auth.currentUser?.uid;
                    if (userId == null) {
                      showCustomSnackBar('로그인이 필요합니다.');
                      return;
                    }
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddressManager(
                          userId: userId,
                          address: address,
                        ),
                      ),
                    );
                    if (result != null) {
                      _loadAddresses(); // 수정 후 목록 새로고침
                    }
                  },
                  child: Text(
                    '수정',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _selectAddress(index),
                  child: const Text(
                    '선택',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
