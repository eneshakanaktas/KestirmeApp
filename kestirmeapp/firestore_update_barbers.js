/**
 * Firestore Veri Güncelleme Script'i
 * 
 * Bu script'i Firebase Console > Firestore > Rules sekmesinde çalıştırabilir
 * veya Firebase Admin SDK ile Node.js'te çalıştırabilirsiniz.
 * 
 * Amaç: Mevcut barbers collection'daki tüm dokümanlara salonName field'ı eklemek
 */

// ============================================
// YÖNTEM 1: Firebase Console (Manuel)
// ============================================

// 1. Firebase Console > Firestore Database'e git
// 2. "barbers" collection'ını aç
// 3. Her berber document'ını aç ve aşağıdaki field'ı ekle:

/*
  Field Name: salonName
  Type: string
  Value: "Elite Kuaför" veya "Modern Barber" veya "Klasik Berber"
*/

// Örnek barber document yapısı:
/*
{
  uid: "barber_uid_1",
  email: "ahmet@example.com",
  salonName: "Elite Kuaför",       // YENİ - Manuel ekle
  phone: "555-1234",
  address: "İstanbul",
  isActive: true,
  ratingCount: 0,
  ratingTotal: 0,
  createdAt: Timestamp
}
*/

// ============================================
// YÖNTEM 2: Firebase Admin SDK (Otomatik)
// ============================================

// Node.js ortamında çalıştır:

const admin = require('firebase-admin');

// Firebase Admin başlat (serviceAccountKey.json gerekli)
admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

async function updateBarbersWithSalonNames() {
  try {
    // Tüm berberleri çek
    const barbersSnapshot = await db.collection('barbers').get();
    
    console.log(`Toplam ${barbersSnapshot.size} berber bulundu.`);
    
    // Salon isimleri havuzu
    const salonNames = [
      'Elite Kuaför',
      'Modern Barber',
      'Klasik Berber'
    ];
    
    let updateCount = 0;
    
    // Batch update (her 500 document'te bir yeni batch)
    const batch = db.batch();
    
    barbersSnapshot.forEach((doc, index) => {
      const data = doc.data();
      
      // Eğer salonName yoksa ekle
      if (!data.salonName) {
        // Round-robin şeklinde salon ata
        const salonName = salonNames[index % salonNames.length];
        
        batch.update(doc.ref, {
          salonName: salonName
        });
        
        updateCount++;
        console.log(`${doc.id} → ${salonName}`);
      } else {
        console.log(`${doc.id} zaten salonName var: ${data.salonName}`);
      }
    });
    
    // Batch'i commit et
    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ ${updateCount} berber güncellendi!`);
    } else {
      console.log('ℹ️ Güncellenecek berber yok.');
    }
    
  } catch (error) {
    console.error('Hata:', error);
  }
}

// Script'i çalıştır
// updateBarbersWithSalonNames();


// ============================================
// YÖNTEM 3: Flutter Kodu İçinden (One-time)
// ============================================

// Flutter uygulaması içinde bir kerelik çalıştır:

/*
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addSalonNamesToBarbers() async {
  final db = FirebaseFirestore.instance;
  
  final barbersSnapshot = await db.collection('barbers').get();
  
  final salonNames = ['Elite Kuaför', 'Modern Barber', 'Klasik Berber'];
  
  for (int i = 0; i < barbersSnapshot.docs.length; i++) {
    final doc = barbersSnapshot.docs[i];
    final data = doc.data();
    
    if (!data.containsKey('salonName')) {
      final salonName = salonNames[i % salonNames.length];
      
      await doc.reference.update({'salonName': salonName});
      
      print('${doc.id} → $salonName güncellendi');
    }
  }
  
  print('Tüm berberler güncellendi!');
}
*/

// ============================================
// TEST: Veri Kontrolü
// ============================================

// Güncellemeden sonra kontrol et:
/*
const testBarbers = async () => {
  const snapshot = await db.collection('barbers').get();
  
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`${doc.id}: ${data.salonName || 'YOK!'}`);
  });
};

// testBarbers();
*/


// ============================================
// ÖRNEK ÇIKTI
// ============================================

/*
Beklenen Firestore yapısı (güncelleme sonrası):

/barbers
  {barber_uid_1}
    email: "ahmet@berber.com"
    salonName: "Elite Kuaför"
    phone: "555-1234"
    isActive: true
    
  {barber_uid_2}
    email: "mehmet@berber.com"
    salonName: "Modern Barber"
    phone: "555-5678"
    isActive: true
    
  {barber_uid_3}
    email: "ali@berber.com"
    salonName: "Klasik Berber"
    phone: "555-9012"
    isActive: true
*/

// ============================================
// KULLANIM TALİMATI
// ============================================

/*
1. YÖNTEM 1 (Manuel) tercih ediyorsan:
   - Firebase Console'a git
   - Her barber document'ına tek tek salonName ekle
   
2. YÖNTEM 2 (Otomatik) tercih ediyorsan:
   - Node.js kurul
   - firebase-admin yükle: npm install firebase-admin
   - serviceAccountKey.json indir (Firebase Console > Project Settings > Service Accounts)
   - Bu script'i çalıştır: node update_barbers.js
   
3. YÖNTEM 3 (Flutter içinden) tercih ediyorsan:
   - Bu fonksiyonu bir debug butona bağla
   - App çalıştır, butona bas, bir kere çalıştır
   - Sonra kodu kaldır

✅ En Kolay: YÖNTEM 1 (Manuel) - 3-5 dakika
✅ En Hızlı: YÖNTEM 2 (Otomatik) - Eğer Node.js biliyorsan
*/
