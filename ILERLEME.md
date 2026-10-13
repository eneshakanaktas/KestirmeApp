# İLERLEME

## Sıradaki adım
- Yeni `kestirmeapp/firestore.rules` dosyasını Firebase Console > Firestore > Rules bölümüne yapıştırıp **Publish** et (Firebase'deki eski deneme kuralları 18 Ocak 2026'da bitti, her şeyi reddediyor).
- Firebase > Authentication > Sign-in method > **Anonymous** açık olmalı (misafir giriş için).
- Firestore > barbers içindeki sahte kayıtları sil: `Um7nj9…` (ENES KUAFÖR, e-postası boş) ve `W6pQI6…` (Misafir Berber Salonu); bunlara bağlı randevuları da sil.
- Uygulamayı web'de uçtan uca dene: müşteri misafir girişi → Enes'ten randevu al → "Misafir Berber (Enes)" ile berber panelinde bildirimi/randevuyu gör. Komut (kestirmeapp klasöründe): `flutter run -d chrome --dart-define=ENES_SIFRE=<şifre>`.
- Randevu ekranlarında "index gerekiyor" hatası çıkarsa hatadaki bağlantıdan index oluştur.
- Groq API anahtarını yenile ve `kestirmeapp/assets/.env` dosyasını depodan çıkar.

## Açık sorular
- `assets/.env` içindeki Groq anahtarı GitHub'da (özel depo) duruyor; yenilenip dosya git'ten çıkarılsın mı?
- İlk commit'teki (`f757986`) Claude imza satırı silinsin mi? (Geçmişi yeniden yazmak için zorla yükleme gerekir.)
- C: diskinde yer kalmadı (Temp ~11 GB); temizlik yapılmadı, derleme için yer açılmalı.

## Günlük
- **Enes (2026-10-13):** Uygulama analiz edildi; ayrıntılı `README.md` yazıldı, GitHub açıklaması/etiketleri güncellendi.
- **Enes (2026-10-13):** Test için geçici misafir girişi eklendi (`kMisafirGirisiAcik`): Müşteri kartı otomatik anonim giriş; berber sayfasında "Misafir Berber (Enes)" düğmesi gerçek enes123@gmail.com hesabıyla girer (şifre `--dart-define=ENES_SIFRE` ile verilir, koda yazılmaz). Web'de test edilirken "permission-denied" çıktı: Firebase'deki eski kurallar bitmişti. `firestore.rules` kodla uyumlu olacak şekilde yeniden yazıldı (henüz Firebase'e yüklenmedi). Bildirim servisinde kural yüzünden bildirim oluşmama sorunu giderildi. Yapay zekâ asistanı artık salonu e-postasıyla buluyor (aynı adlı kopyalara randevu gitmesin). Müşteri ana sayfasında hata mesajı artık ayrıntı gösteriyor.
