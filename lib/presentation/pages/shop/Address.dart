import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pet_moment/core/utils/snackbar_utils.dart';

class AddressManager extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? address; // 수정할 기존 주소 (없으면 추가)
  const AddressManager({
    super.key,
    required this.userId,
    this.address,
  });

  @override
  State<AddressManager> createState() => _AddressManagerState();
}

class _AddressManagerState extends State<AddressManager> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _detailAddressController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDefaultAddress = false;
  final String apiKey = 'da71fd971443a91ac37366fd70bd0e73';
  List<Map<String, dynamic>> _results = <Map<String, dynamic>>[];
  String? _selectedAddress;
  bool _showAddressForm = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // 수정모드인 경우 기존 데이터를 초기화
    if (widget.address != null) {
      _nameController.text = widget.address!['name'] ?? '';
      _phoneController.text = widget.address!['phone'] ?? '';
      _selectedAddress = widget.address!['mainAddress'] ?? '';
      _detailAddressController.text = widget.address!['detailAddress'] ?? '';
      _isDefaultAddress = widget.address!['isDefault'] ?? false;
      _showAddressForm = true;
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      showCustomSnackbar(context, '검색어를 입력해주세요.');
      return;
    }

    setState(() {
      _isSearching = true;
      _results = <Map<String, dynamic>>[];
    });

    try {
      // 주소 검색 API 호출
      final addressUrl = Uri.parse(
          'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(query)}');

      // 키워드 검색 API 호출
      final keywordUrl = Uri.parse(
          'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}');

      final headers = {'Authorization': 'KakaoAK $apiKey'};

      // 두 API를 동시에 호출
      final responses = await Future.wait([
        http.get(addressUrl, headers: headers),
        http.get(keywordUrl, headers: headers),
      ]);

      final addressResponse = responses[0];
      final keywordResponse = responses[1];

      if (addressResponse.statusCode == 200 &&
          keywordResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        final keywordData = json.decode(keywordResponse.body);

        // 주소 검색 결과 처리
        final addressResults = (addressData['documents'] as List)
            .map((doc) => {
                  'type': 'address',
                  'road_address': doc['road_address'],
                  'address': doc['address'],
                  'place_name': null,
                })
            .toList();

        // 키워드 검색 결과 처리
        final keywordResults = (keywordData['documents'] as List)
            .where((doc) =>
                doc['road_address_name'] != null || doc['address_name'] != null)
            .map((doc) => {
                  'type': 'keyword',
                  'road_address': {
                    'address_name': doc['road_address_name'],
                    'building_name': doc['place_name'],
                  },
                  'address': {
                    'address_name': doc['address_name'],
                  },
                  'place_name': doc['place_name'],
                })
            .toList();

        final combinedResults = [...addressResults, ...keywordResults];

        setState(() {
          _results = combinedResults;
        });

        if (_results.isEmpty) {
          showCustomSnackbar(context, '검색 결과가 없습니다.');
        }
      } else if (addressResponse.statusCode == 401 ||
          keywordResponse.statusCode == 401) {
        showCustomSnackbar(context, '인증에 실패했습니다. API 키를 확인해주세요.');
      } else {
        showCustomSnackbar(context, '검색 중 오류가 발생했습니다.');
      }
    } catch (e) {
      showCustomSnackbar(context, '네트워크 오류가 발생했습니다.');
      print('Exception: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    try {
      final userDoc = _firestore.collection('users').doc(widget.userId);

      // 기본 배송지로 설정 시 기존 기본 배송지는 해제
      if (_isDefaultAddress) {
        final existingDefault = await userDoc
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();

        for (var doc in existingDefault.docs) {
          await doc.reference.update({'isDefault': false});
        }
      }

      final addressData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'mainAddress': _selectedAddress,
        'detailAddress': _detailAddressController.text,
        'isDefault': _isDefaultAddress,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.address != null) {
        // 수정모드: 기존 문서를 업데이트
        final addressId = widget.address!['id'];
        await userDoc
            .collection('addresses')
            .doc(addressId)
            .update(addressData);
        showCustomSnackbar(context, '배송지가 업데이트되었습니다.');
      } else {
        // 추가모드: 새 문서를 생성
        await userDoc.collection('addresses').add(addressData);
        showCustomSnackbar(context, '배송지가 저장되었습니다.');
      }
      Navigator.pop(context, addressData);
    } catch (e) {
      showCustomSnackbar(context, '배송지 저장 중 오류가 발생했습니다.');
      print('Error saving address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '배송지 입력',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 18,
            fontFamily: 'Pretendard Variable',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: Column(children: [
        if (!_showAddressForm) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '지번, 도로명, 건물명(지하철역, 학교 등)으로 검색',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      _searchAddress(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (value) => _searchAddress(value.trim()),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final roadAddress =
                        result['road_address']?['address_name'] as String?;
                    final address =
                        result['address']?['address_name'] as String?;
                    final placeName = result['place_name'] as String?;

                    if (roadAddress == null && address == null) {
                      return const SizedBox.shrink();
                    }

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAddress = roadAddress ?? address;
                          _showAddressForm = true;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (placeName != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  placeName,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard Variable',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                              ),
                            if (roadAddress != null)
                              Text(
                                '도로명) $roadAddress',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 15,
                                ),
                              ),
                            if (address != null)
                              Text(
                                '지번) $address',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_isSearching)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ] else ...[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '받는 분 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '받는 분',
                      hintText: '이름을 입력해주세요',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '연락처',
                      hintText: '휴대폰 번호를 입력해주세요',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '배송지 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedAddress ?? '',
                      style: const TextStyle(
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _detailAddressController,
                    decoration: const InputDecoration(
                      labelText: '상세주소',
                      hintText: '상세주소를 입력해주세요',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '기본 배송지로 설정',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDefaultAddress,
                        onChanged: (value) {
                          setState(() {
                            _isDefaultAddress = value;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                        thumbColor:
                            const MaterialStatePropertyAll<Color>(Colors.white),
                      ),
                    ],
                  ),

                  // 삭제하기 버튼 추가
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          if (widget.address != null) {
                            final addressId = widget.address!['id'];
                            await _firestore
                                .collection('users')
                                .doc(widget.userId)
                                .collection('addresses')
                                .doc(addressId)
                                .delete();

                            showCustomSnackbar(context, '배송지가 삭제되었습니다');

                            // 잠시 후 화면 종료
                            Future.delayed(const Duration(milliseconds: 800),
                                () {
                              Navigator.pop(context);
                            });
                          }
                        } catch (e) {
                          showCustomSnackbar(context, '배송지 삭제에 실패했습니다');
                          print('Error deleting address: $e');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '삭제하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailAddressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
