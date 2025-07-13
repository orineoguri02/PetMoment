import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:shimmer/shimmer.dart';

class ChangeProfile extends StatefulWidget {
  const ChangeProfile({super.key});

  @override
  State<ChangeProfile> createState() => _ChangeProfileState();
}

class _ChangeProfileState extends State<ChangeProfile> {
  final TextEditingController _nicknameController = TextEditingController();
  String? _profileImageUrl;
  String? _selectedDefaultAsset; // 선택된 기본 에셋
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // 갤러리에서 선택한 바이트
  bool _isUploading = false;

  // assets 폴더에 있는 기본 이미지 목록
  final List<String> _defaultAssets = [
    'assets/PetMoment.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _selectedDefaultAsset = null;
          _profileImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, '이미지 선택 중 오류가 발생했습니다.');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      setState(() => _isUploading = true);

      // 이전 URL 이미지 삭제
      if (_profileImageUrl != null &&
          _profileImageUrl!.startsWith('https://')) {
        try {
          await FirebaseStorage.instance.refFromURL(_profileImageUrl!).delete();
        } catch (_) {}
      }

      final emailFolder = user.email!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('Album')
          .child(emailFolder)
          .child('profile')
          .child('$emailFolder.png');

      final snapshot = await storageRef.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/png'),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (mounted) showCustomSnackbar(context, '이미지 업로드 중 오류가 발생했습니다.');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _nicknameController.text = data['nickname'] ?? '';
      _profileImageUrl = data['profileImageUrl'];
      // 에셋 경로인지 판단
      if (_profileImageUrl != null && _profileImageUrl!.startsWith('assets/')) {
        _selectedDefaultAsset = _profileImageUrl;
      }
    });
  }

  Future<void> _saveProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? finalImageRef = _profileImageUrl;

      if (_imageBytes != null) {
        finalImageRef = await _uploadImage();
      } else if (_selectedDefaultAsset != null) {
        // 기본 에셋 선택 시, 에셋 경로를 그대로 사용
        finalImageRef = _selectedDefaultAsset;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'nickname': _nicknameController.text.trim(),
        'profileImageUrl': finalImageRef ?? '',
      });

      if (mounted) {
        showCustomSnackbar(context, '프로필이 저장되었습니다.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, '프로필 저장 중 오류가 발생했습니다.');
    }
  }

  Widget _buildProfileCircleAvatar() {
    if (_imageBytes != null) {
      // 갤러리에서 선택한 이미지
      return CircleAvatar(
        radius: 90,
        backgroundImage: MemoryImage(_imageBytes!),
        child: _buildCameraIcon(),
      );
    } else if (_selectedDefaultAsset != null) {
      // 기본 에셋 이미지
      return CircleAvatar(
        radius: 90,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage(_selectedDefaultAsset!),
        child: _buildCameraIcon(),
      );
    } else if (_profileImageUrl != null &&
        _profileImageUrl!.startsWith('http')) {
      // 원격 URL 이미지
      return CachedNetworkImage(
        imageUrl: _profileImageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 90,
          backgroundImage: imageProvider,
          child: _buildCameraIcon(),
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 90,
          backgroundColor: Colors.grey[300],
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: 90,
          backgroundImage: const AssetImage('assets/PetMoment.png'),
          child: _buildCameraIcon(),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 90,
        backgroundImage: const AssetImage('assets/PetMoment.png'),
        child: _buildCameraIcon(),
      );
    }
  }

  Widget _buildCameraIcon() {
    return Align(
      alignment: Alignment.bottomRight,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.black54,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('프로필 변경',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : _saveProfileData,
              child: Text(
                '저장',
                style: TextStyle(
                    color: _isUploading ? Colors.grey : Colors.black,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickImage,
                    child: _buildProfileCircleAvatar(),
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('기본 이미지 선택',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _defaultAssets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final asset = _defaultAssets[index];
                        final selected = asset == _selectedDefaultAsset;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDefaultAsset = asset;
                              _imageBytes = null;
                              _profileImageUrl = asset;
                            });
                          },
                          child: CircleAvatar(
                            radius: selected ? 38 : 34,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: selected ? 35 : 32,
                              backgroundImage: AssetImage(asset),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
