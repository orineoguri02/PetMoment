import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:flutter/painting.dart' as painting;

class PolaroidAddScreen extends StatefulWidget {
  final String userId;
  final String albumId;
  final String imagePath;
  final String albumName;

  const PolaroidAddScreen({
    Key? key,
    required this.userId,
    required this.albumId,
    required this.imagePath,
    required this.albumName,
  }) : super(key: key);

  @override
  State<PolaroidAddScreen> createState() => _PolaroidAddScreenState();
}

class _PolaroidAddScreenState extends State<PolaroidAddScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // 이미지 변환을 위한 컨트롤러
  final TransformationController _transformationController =
      TransformationController();

  // RepaintBoundary를 위한 GlobalKey 추가
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  DateTime _selectedDate = DateTime.now();
  final int _startYear = 2001;
  final DateTime _today = DateTime.now();

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _transformationController.dispose();
    painting.PaintingBinding.instance.imageCache
        .evict(FileImage(File(widget.imagePath)));
    super.dispose();
  }

  void _handleTextChanged(String text) {
    final lines = text.split('\n');
    if (lines.length > 2) {
      final limited = lines.take(2).join('\n');
      _textController.value = TextEditingValue(
        text: limited,
        selection: TextSelection.collapsed(offset: limited.length),
      );
      _textFocusNode.unfocus();
    }
  }

  Map<String, dynamic> getTransformationData() {
    final matrix = _transformationController.value;
    final translateX = matrix.getTranslation().x;
    final translateY = matrix.getTranslation().y;
    final scale = matrix.getMaxScaleOnAxis();

    return {
      'translateX': translateX,
      'translateY': translateY,
      'scale': scale,
    };
  }

  void _resetTransformation() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  /// 변환된 이미지를 캡처해서 Uint8List로 반환
  Future<Uint8List> _captureTransformedImage() async {
    try {
      // RepaintBoundary에서 이미지 캡처
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // 고해상도로 캡처 (devicePixelRatio 적용)
      ui.Image image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // PNG를 JPEG로 압축
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithList(
        pngBytes,
        quality: 90,
        format: CompressFormat.jpeg,
      );

      return compressedBytes ?? pngBytes;
    } catch (e) {
      debugPrint('이미지 캡처 실패: $e');
      // 캡처 실패 시 원본 이미지 사용
      return await _compressImageBytes(File(widget.imagePath));
    }
  }

  /// 원본 파일을 메모리에 바로 압축해 Uint8List로 반환 (quality 90)
  Future<Uint8List> _compressImageBytes(File srcFile) async {
    final Uint8List? result = await FlutterImageCompress.compressWithFile(
      srcFile.path,
      quality: 90,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    return result ?? await srcFile.readAsBytes();
  }

  void _showIOSDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height * 0.25,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 40,
                color: const Color(0xFFF8F8F8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    CupertinoButton(
                      child: const Text('완료'),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime(_startYear),
                  maximumDate: _today,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      _selectedDate = newDateTime;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadPhoto() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('albums')
          .doc(widget.albumId)
          .collection('polaroid');

      final transformData = getTransformationData();
      final docRef = col.doc();

      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? widget.userId;

      final storageRef = FirebaseStorage.instance
          .ref('Album/$email/${widget.albumName}/${docRef.id}.jpg');

      // 변환된 이미지 캡처 및 압축
      final Uint8List data = await _captureTransformedImage();

      final uploadTask = storageRef.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      await docRef.set({
        'imageUrl': imageUrl,
        'imageStoragePath': storageRef.fullPath,
        'text': _textController.text.replaceAll('\n', '\\n'),
        'timestamp': Timestamp.fromDate(_selectedDate),
        'imageTransform': transformData, // 참고용으로 유지
      });

      if (!mounted) return;
      Navigator.pop(context, true);
      showCustomSnackbar(context, "기록이 저장되었습니다.");
    } catch (e) {
      debugPrint('업로드 중 오류: $e');
      try {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email ?? widget.userId;
        final storageRef = FirebaseStorage.instance.ref(
            'Album/$email/${widget.albumName}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.delete();
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업로드 중 오류가 발생했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 26),
                          onPressed: _resetTransformation,
                          tooltip: '이미지 위치 초기화',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 0.75,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: AspectRatio(
                              aspectRatio: 0.8,
                              child: ClipRRect(
                                child: RepaintBoundary(
                                  key: _repaintBoundaryKey,
                                  child: Stack(
                                    children: [
                                      // 안내 텍스트 배경
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.02),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '드래그하여 위치 조정\n손가락 두 개로 확대/축소',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black45,
                                              fontSize: 12,
                                              fontFamily: 'HS유지체',
                                            ),
                                          ),
                                        ),
                                      ),
                                      // InteractiveViewer로 이미지 조작
                                      InteractiveViewer(
                                        transformationController:
                                            _transformationController,
                                        boundaryMargin: EdgeInsets.zero,
                                        panEnabled: true,
                                        scaleEnabled: true,
                                        minScale: 1.0,
                                        maxScale: 4.0,
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Image.file(
                                            File(widget.imagePath),
                                            fit: BoxFit.cover,
                                            cacheWidth: (MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    MediaQuery.of(context)
                                                        .devicePixelRatio)
                                                .round(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: TextField(
                                controller: _textController,
                                focusNode: _textFocusNode,
                                style: const TextStyle(fontFamily: 'HS유지체'),
                                decoration: const InputDecoration(
                                  hintText: '텍스트를 입력하세요',
                                  hintStyle: TextStyle(fontFamily: 'HS유지체'),
                                  border: InputBorder.none,
                                ),
                                maxLines: 2,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                onChanged: _handleTextChanged,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: GestureDetector(
                              onTap: _showIOSDatePicker,
                              child: Container(
                                width: 100,
                                height: 42,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  DateFormat('yyyy.MM.dd')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontFamily: 'HS유지체',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadPhoto,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          backgroundColor: Colors.white,
                        ),
                        child: _isUploading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _uploadProgress == 0.0
                                      ? null
                                      : _uploadProgress,
                                ),
                              )
                            : const Text(
                                '작성 완료',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
