# ✂️ Kestirme — Berber Randevu Uygulaması

**Kestirme**, müşterilerle berber salonlarını buluşturan bir mobil randevu uygulamasıdır. Müşteri salonları görür, istediği gün ve saate randevu alır; berber randevuyu onaylar, takip eder ve geçmişini tutar. Randevu, telefonda arama yapmadan **yapay zekâ asistanıyla sohbet ederek** de alınabilir.

> Flutter + Firebase ile yazıldı. Arayüz Türkçedir, koyu ve "premium" bir tasarıma sahiptir.

---

## 🎯 Ne işe yarar?

| Sorun | Kestirme'nin çözümü |
|---|---|
| Berbere telefonla randevu almak zahmetli | Uygulamadan birkaç dokunuşla ya da sohbet ederek randevu |
| Aynı saate iki kişi yazılabiliyor | Çakışma kontrolü: dolu saat tekrar alınamaz |
| Randevu durumu belirsiz | Bekliyor → Onaylandı → Tamamlandı / İptal akışı ve anlık bildirimler |
| Berberin kalitesini bilmek zor | Tamamlanan randevudan sonra 1–5 puan ve yorum |

---

## 👥 İki tür kullanıcı

Uygulamada iki ayrı giriş vardır; kayıt olurken rol seçilir ve giriş yapınca kullanıcı kendi paneline yönlenir.

### 🙋 Müşteri
- **Salon listesi:** Aktif salonları puanlarıyla birlikte görür.
- **Salon detayı:** Adres, telefon, puan ve değerlendirmeler.
- **Randevu oluşturma:** Tarih ve saat seçer (Pazar günleri seçilemez).
- **Randevularım:** Aktif randevular ve **geri sayım sayacı** (randevuya ne kadar kaldı).
- **Randevu iptali:** Randevuya 60 dakikadan fazla varsa iptal edebilir.
- **Geçmiş randevular** ve tamamlanan randevu için **puan + yorum** verme (her randevu yalnızca bir kez değerlendirilir).
- **Harita:** Salonları OpenStreetMap üzerinde işaretli görür.
- **Bildirimler:** Randevu oluştu / onaylandı / iptal edildi / tamamlandı.
- **Yapay zekâ asistanı:** Sohbet ederek randevu alır (aşağıya bakın).
- **Şifre değiştirme.**

### 💈 Berber
- **Randevu defteri:** Gelen randevuları görür; bekleyenleri **onaylar** veya **iptal eder**, onaylananları **tamamlandı** yapar.
- **Aktif randevular** ve **geçmiş randevular** ekranları.
- **Salon profili:** Salon adı, telefon, adres düzenler; salonu **aktif/pasif** yapar (pasif salon müşterilere görünmez).
- **Puan ve yorumlar:** Müşterilerden gelen ortalama puanı görür.
- **Bildirimler:** Yeni randevu talebi ve müşteri iptalleri.

---

## 🤖 Yapay zekâ randevu asistanı

Müşteri "Asistan" butonundan **Berber Asistanı** ile Türkçe konuşur. Asistan:

1. Hangi salonu istediğini sorar,
2. Tarih ve saati sorar ("yarın", "23 Aralık" gibi ifadeleri anlar),
3. Ad-soyad ve telefon (+90 ile) alır,
4. Bilgiler tamamsa randevuyu otomatik oluşturur.

Ayrıca saç kesimi/bakım önerileri verir, Pazar günü ve 30 dakikalık düzene uymayan saatleri nazikçe düzeltir. Cevaplar **yazıldıkça akar** (streaming). Sohbet geçmişi telefonda, **kullanıcıya özel** saklanır.

Arka planda: [Groq](https://groq.com) üzerinden `llama-3.3-70b-versatile` modeli kullanılır. Model, randevu için hazır olduğunda bir JSON ("create_appointment") döner; uygulama bunu okur ve normal randevu servisine iletir.

---

## 📋 İş kuralları

- **Çalışma günleri:** Pazartesi – Cumartesi. **Pazar kapalı.**
- **Saatler:** 09:00 – 00:00 arası, **30 dakikalık** aralıklarla.
- **Çakışma:** Aynı salon + gün + saat için iptal edilmemiş randevu varsa yeni randevu reddedilir.
- **Geçmişe randevu yok** (2 dakika tolerans).
- **Durum akışı:** `bekliyor → onaylandı → tamamlandı`; `bekliyor/onaylandı → iptal`. Tamamlanan ve iptal edilen değiştirilemez.
- **Müşteri iptali:** Randevuya 60 dakikadan az kala yapılamaz.
- **Değerlendirme:** Yalnızca tamamlanmış randevu, yalnızca bir kez, puan 1–5.

---

## 🧱 Teknik yapı

| Katman | Kullanılan |
|---|---|
| Uygulama | Flutter (Dart 3.10), Material 3, koyu tema |
| Giriş / hesap | Firebase Authentication (e-posta + şifre) |
| Veritabanı | Cloud Firestore (anlık güncellenen akışlar) |
| Yapay zekâ | Groq API (Llama 3.3 70B), Dio ile akış (stream) |
| Harita | flutter_map + OpenStreetMap |
| Tasarım | Google Fonts (Playfair Display, Montserrat), flutter_animate, cam efekti (glassmorphism) |
| Yerel kayıt | shared_preferences (sohbet geçmişi) |
| Diğer | flutter_markdown, flutter_rating_bar, timeago, intl (Türkçe tarih) |

Desteklenen platformlar: Android, iOS, Web, Windows, macOS, Linux (Firebase ayarları Android/iOS/Web/Windows/macOS için hazır).

### Klasör yapısı

```
kestirmeapp/
├─ lib/
│  ├─ main.dart            Uygulama girişi, tema, sayfa yolları
│  ├─ models/              Berber, sohbet mesajı
│  ├─ pages/               Tüm ekranlar (müşteri, berber, giriş, sohbet, harita…)
│  ├─ services/            İş mantığı
│  │   ├─ appointment_service.dart   Randevu oluştur / durum değiştir / çakışma
│  │   ├─ evaluation_service.dart    Puanlama (tek seferlik, atomik işlem)
│  │   ├─ notification_service.dart  Uygulama içi bildirimler
│  │   ├─ barber_service.dart        Salon profili ve aktiflik
│  │   ├─ user_service.dart          Kullanıcı rolü (müşteri/berber)
│  │   ├─ groq_service.dart          Yapay zekâ ile konuşma
│  │   ├─ ai_appointment_parser.dart AI cevabından randevu bilgisini okur
│  │   └─ chat_storage_service.dart  Sohbet geçmişi
│  ├─ theme/ widgets/      Ortak tasarım parçaları (geri sayım, cam kart, arka plan)
│  └─ utils/               Salon adı eşleştirme
├─ firestore.rules         Veritabanı güvenlik kuralları
├─ android/ ios/ web/ windows/ macos/ linux/   Platform dosyaları
└─ pubspec.yaml            Paket listesi
```

### Veritabanı (Firestore)

| Koleksiyon | İçerik |
|---|---|
| `users` | Kullanıcının rolü (`customer` / `barber`) |
| `barbers` | Salon adı, telefon, adres, aktiflik, toplam puan ve puan sayısı |
| `appointments` | Müşteri, berber, tarih, saat, ad, telefon, durum, değerlendirildi mi |
| `notifications` | Kullanıcıya giden bildirimler, okundu bilgisi |
| `barbers/{id}/reviews` | Müşteri puanı ve yorumu |

`firestore.rules` dosyasında kimin neyi okuyup yazabileceği tanımlıdır: müşteri yalnız kendi randevusunu, berber yalnız kendine gelen randevuyu görür; durum geçişleri ve puanlama kurallara bağlıdır; her şey varsayılan olarak yasaktır.

---

## 🚀 Çalıştırma

**Gerekenler:** [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.10+), bir Firebase projesi, bir [Groq API anahtarı](https://console.groq.com/) (ücretsiz).

```bash
cd kestirmeapp
flutter pub get

# Yapay zekâ anahtarı: assets/.env.example dosyasını assets/.env adıyla kopyalayıp kendi anahtarınızı yazın
# (flutter run bu dosya olmadan derlenmez)

flutter run
```

Kendi Firebase projenizi kullanacaksanız `flutterfire configure` ile `lib/firebase_options.dart` dosyasını yenileyin ve `firestore.rules` dosyasını Firebase'e yükleyin.

---

## ⚠️ Bilinen eksikler / yapılacaklar

- **Güvenlik:** `assets/.env` (Groq anahtarı) artık depoda yok (`.gitignore`'da); örnek dosya `assets/.env.example`. Uygulamanın içine konan anahtar, uygulamayı kuran herkes tarafından çıkarılabilir; kalıcı çözüm yapay zekâ isteğini kendi sunucumuzdan geçirmektir.
- **Güvenlik kuralları:** `firestore.rules` kodla uyumlu hâle getirildi (bildirim, randevu silme, `reviews`). Dosya Firebase Console > Firestore > Rules bölümüne **elle yüklenmelidir**; Firebase'deki eski deneme kuralları süresi dolduğu için tüm istekleri reddeder. Yeni kurallar henüz gerçek kullanımda tam denenmedi.
- **Çift randevu kontrolü:** Müşteri başkasının randevusunu okuyamadığı için çakışma kontrolü şu an etkisiz kalabilir; kalıcı çözüm sunucu tarafında yapılmalı.
- **Test amaçlı misafir girişi:** `kMisafirGirisiAcik` ([auth_gate_page.dart](kestirmeapp/lib/pages/auth_gate_page.dart)) açıkken "Müşteri" kartı otomatik misafir (anonim) girişi yapar ve berber sayfasında "Misafir Berber (Enes)" düğmesi görünür. Bu düğme için Firebase'de **Anonymous** girişi açık olmalı ve uygulama `flutter run --dart-define=ENES_SIFRE=1234567` ile başlatılmalıdır (enes123@gmail.com test hesabının şifresi; koda yazılmaz, yalnızca komutla verilir). Yayına çıkmadan önce `false` yapın.
- **Salonlar sabit kodlu:** Üç salon (ENES KUAFÖR, BERBER RAGO, Hamza Image Maker) e-posta adreslerine ve harita koordinatlarına koddan bağlı. Yeni salon eklemek şimdilik kod değişikliği ister.
- **Bildirimler uygulama içidir;** telefona anlık (push) bildirim gitmez.
- Test kapsamı yok (yalnızca Flutter'ın örnek testi).

---

## 👨‍💻 Ekip

Enes, Hamza, Ragıp
