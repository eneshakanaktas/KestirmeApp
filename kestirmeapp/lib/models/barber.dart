import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String uid;
  final String salonName;
  final String address;
  final String phone;
  final String email;
  final bool isActive;
  final int ratingCount;
  final double ratingTotal;

  Barber({
    required this.uid,
    required this.salonName,
    required this.address,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.ratingCount,
    required this.ratingTotal,
  });

  factory Barber.fromMap(Map<String, dynamic> data, String uid) {
    return Barber(
      uid: uid,
      salonName: data['salonName'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? false,
      ratingCount: (data['ratingCount'] ?? 0) as int,
      ratingTotal: (data['ratingTotal'] ?? 0.0) as double,
    );
  }

  factory Barber.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Barber.fromMap(data, doc.id);
  }

  double get averageRating {
    if (ratingCount == 0) return 0.0;
    return ratingTotal / ratingCount;
  }
}
