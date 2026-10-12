import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Kullanıcı işlemlerini yöneten servis
/// Firestore'da kullanıcı bilgilerini ve rol bilgisini saklar
class UserService {
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Users collection referansı
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Kullanıcı rol bilgisini Firestore'a kaydeder
  /// 
  /// [user] Firebase Authentication'dan gelen kullanıcı
  /// [role] Kullanıcının rolü ("customer" veya "barber")
  Future<void> createUserRole({
    required User user,
    required String role,
  }) async {
    try {
      // Firestore'a kullanıcı bilgilerini kaydet
      await _usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Kullanıcı başarıyla kaydedildi: ${user.email} - Rol: $role');
      
    } catch (e) {
      debugPrint('Kullanıcı kaydı başarısız: $e');
      rethrow;
    }
  }

  /// Kullanıcının rol bilgisini getirir
  /// 
  /// [uid] Kullanıcının Firebase Auth uid'si
  /// Returns: "customer", "barber" veya null
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Kullanıcı rolü getirilemedi: $e');
      return null;
    }
  }

  /// Mevcut kullanıcının rol bilgisini getirir
  /// 
  /// Returns: "customer", "barber" veya null
  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      debugPrint('Giriş yapmış kullanıcı bulunamadı');
      return null;
    }
    
    return await getUserRole(user.uid);
  }
}
