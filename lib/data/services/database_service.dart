import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 사용자 관련 메소드
  static Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.userId).set(user.toFirestore());
  }

  static Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  static Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // 앨범 관련 메소드
  static Future<String> createAlbum(String userId, AlbumModel album) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .add(album.toFirestore());
    return docRef.id;
  }

  static Future<AlbumModel?> getAlbum(String userId, String albumId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .get();
    return doc.exists ? AlbumModel.fromFirestore(doc) : null;
  }

  static Stream<QuerySnapshot> getUserAlbums(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateAlbum(String userId, String albumId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .update(data);
  }

  static Future<void> deleteAlbum(String userId, String albumId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .delete();
  }

  // 폴라로이드 관련 메소드
  static Future<String> createPolaroid(String userId, String albumId, PolaroidModel polaroid) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .collection('polaroid')
        .add(polaroid.toFirestore());
    return docRef.id;
  }

  static Future<PolaroidModel?> getPolaroid(String userId, String albumId, String polaroidId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .collection('polaroid')
        .doc(polaroidId)
        .get();
    return doc.exists ? PolaroidModel.fromFirestore(doc) : null;
  }

  static Stream<QuerySnapshot> getAlbumPolaroids(String userId, String albumId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .collection('polaroid')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updatePolaroid(String userId, String albumId, String polaroidId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .collection('polaroid')
        .doc(polaroidId)
        .update(data);
  }

  static Future<void> deletePolaroid(String userId, String albumId, String polaroidId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .collection('polaroid')
        .doc(polaroidId)
        .delete();
  }

  // 쇼핑 관련 메소드
  static Future<List<Product>> getShoppingProducts() async {
    final snapshot = await _firestore.collection('Shopping').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product(
        category: Category.values.firstWhere(
          (e) => e.toString() == 'Category.${data['category']}',
          orElse: () => Category.all,
        ),
        id: data['id'].toString(),
        name: data['name'] as String,
        price: data['price'] as int,
        image: data['image'] ?? 'assets/Album_de.png',
      );
    }).toList();
  }

  // 사용자의 모든 데이터 삭제 (탈퇴 시)
  static Future<void> deleteAllUserData(String userId) async {
    final batch = _firestore.batch();
    
    // 사용자의 모든 앨범 삭제
    final albumsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .get();
    
    for (final albumDoc in albumsSnapshot.docs) {
      // 각 앨범의 폴라로이드 삭제
      final polaroidsSnapshot = await albumDoc.reference
          .collection('polaroid')
          .get();
      
      for (final polaroidDoc in polaroidsSnapshot.docs) {
        batch.delete(polaroidDoc.reference);
      }
      
      batch.delete(albumDoc.reference);
    }
    
    // 사용자 문서 삭제
    batch.delete(_firestore.collection('users').doc(userId));
    
    // 전역 컬렉션에서 사용자 데이터 삭제
    final collections = ['posts', 'comments', 'likes'];
    for (final collection in collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    
    await batch.commit();
  }
} 