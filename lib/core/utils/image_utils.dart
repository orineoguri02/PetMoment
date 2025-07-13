import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants/index.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  
  // 갤러리에서 이미지 선택
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }
  
  // 카메라에서 이미지 촬영
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }
  
  // 여러 이미지 선택
  static Future<List<File>> pickMultipleImages({int? maxImages}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        limit: maxImages,
      );
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
  
  // 이미지 압축
  static Future<File?> compressImage(
    File file, {
    int quality = AppConstants.imageCompressQuality,
    int minWidth = AppConstants.imageMinWidth,
    int minHeight = AppConstants.imageMinHeight,
  }) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'\.'));
      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
      
      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
  
  // 이미지를 바이트 배열로 변환
  static Future<Uint8List?> imageToBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error converting image to bytes: $e');
      return null;
    }
  }
  
  // 애셋 이미지를 바이트 배열로 변환
  static Future<Uint8List?> assetToBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Error converting asset to bytes: $e');
      return null;
    }
  }
  
  // 이미지 파일 크기 확인
  static Future<int> getImageFileSize(File imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      print('Error getting image file size: $e');
      return 0;
    }
  }
  
  // 이미지 파일 크기를 MB로 변환
  static double bytesToMB(int bytes) {
    return bytes / (1024 * 1024);
  }
  
  // 이미지 파일 크기를 KB로 변환
  static double bytesToKB(int bytes) {
    return bytes / 1024;
  }
  
  // 파일 크기를 읽기 쉬운 형태로 변환
  static String formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }
  
  // 이미지 선택 옵션 다이얼로그 표시
  static Future<File?> showImageSourceDialog({
    required Function() onCameraPressed,
    required Function() onGalleryPressed,
  }) async {
    // 이 함수는 UI 컨텍스트가 필요하므로 위젯에서 구현해야 합니다.
    // 여기서는 유틸리티 함수의 틀만 제공합니다.
    throw UnimplementedError('This method should be implemented in UI layer');
  }
  
  // 이미지 확장자 검증
  static bool isValidImageExtension(String fileName) {
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }
  
  // 이미지 파일 최대 크기 검증 (MB 단위)
  static bool isValidImageSize(int fileSizeInBytes, double maxSizeInMB) {
    final fileSizeInMB = bytesToMB(fileSizeInBytes);
    return fileSizeInMB <= maxSizeInMB;
  }
  
  // 파일 이름에서 확장자 추출
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }
  
  // 파일명 생성 (타임스탬프 기반)
  static String generateFileName({String extension = 'jpg'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}.${extension}';
  }
  
  // 이미지 회전 정보 제거 (EXIF 데이터 정리)
  static Future<File?> removeExifData(File imageFile) async {
    try {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.absolute.path}_no_exif.jpg',
        quality: 100,
        keepExif: false,
      );
      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      print('Error removing EXIF data: $e');
      return null;
    }
  }
} 