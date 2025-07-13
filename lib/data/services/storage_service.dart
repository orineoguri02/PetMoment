import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // 프로필 이미지 업로드
  static Future<String> uploadProfileImage(String userId, Uint8List imageData) async {
    final ref = _storage.ref().child('profiles').child('$userId.jpg');
    final uploadTask = ref.putData(imageData);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 앨범 커버 이미지 업로드
  static Future<String> uploadAlbumCover(String userId, String albumId, File imageFile) async {
    final compressedFile = await _compressImage(imageFile);
    final ref = _storage.ref().child('albums').child(userId).child(albumId).child('cover.jpg');
    final uploadTask = ref.putFile(compressedFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 폴라로이드 이미지 업로드
  static Future<String> uploadPolaroidImage(String userId, String albumId, File imageFile) async {
    final compressedFile = await _compressImage(imageFile);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('polaroids').child(userId).child(albumId).child(fileName);
    final uploadTask = ref.putFile(compressedFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 이미지 데이터로 업로드 (바이트 배열)
  static Future<String> uploadImageData(String userId, String albumId, Uint8List imageData, String fileName) async {
    final ref = _storage.ref().child('polaroids').child(userId).child(albumId).child(fileName);
    final uploadTask = ref.putData(imageData);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 이미지 압축
  static Future<File> _compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'\.'));
    final splitted = filePath.substring(0, lastIndex);
    final outPath = '${splitted}_compressed.jpg';
    
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 85,
      minWidth: 1920,
      minHeight: 1080,
    );
    
    return compressedFile != null ? File(compressedFile.path) : file;
  }

  // 파일 삭제
  static Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  // 사용자의 모든 파일 삭제
  static Future<void> deleteAllUserFiles(String userId) async {
    try {
      // 프로필 이미지 삭제
      final profileRef = _storage.ref().child('profiles').child('$userId.jpg');
      await profileRef.delete().catchError((e) => print('Profile image not found'));

      // 앨범 폴더 삭제
      final albumsRef = _storage.ref().child('albums').child(userId);
      await _deleteFolder(albumsRef);

      // 폴라로이드 폴더 삭제
      final polaroidsRef = _storage.ref().child('polaroids').child(userId);
      await _deleteFolder(polaroidsRef);

      // 레거시 경로 삭제 (기존 코드와의 호환성)
      final legacyRef = _storage.ref().child('Album').child(userId);
      await _deleteFolder(legacyRef);
    } catch (e) {
      print('Error deleting user files: $e');
    }
  }

  // 폴더 및 하위 파일 모두 삭제
  static Future<void> _deleteFolder(Reference folderRef) async {
    try {
      final listResult = await folderRef.listAll();
      
      // 모든 파일 삭제
      for (final item in listResult.items) {
        await item.delete();
      }
      
      // 모든 하위 폴더 삭제
      for (final prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      print('Error deleting folder: $e');
    }
  }

  // 업로드 진행률 추적
  static Stream<double> uploadWithProgress(String userId, String albumId, File imageFile) {
    return Stream.fromFuture(_compressImage(imageFile))
        .asyncExpand((compressedFile) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('polaroids').child(userId).child(albumId).child(fileName);
      final uploadTask = ref.putFile(compressedFile);
      
      return uploadTask.snapshotEvents.map((snapshot) {
        return snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });
  }
} 