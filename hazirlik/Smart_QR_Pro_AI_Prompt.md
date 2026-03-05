# MASTER PROMPT: Smart QR Pro - Evrensel Ürün Yönetim Sistemi (Flutter v1.0.0)

Bu doküman, "Smart QR Pro" Flutter uygulamasının tüm teknik mimarisini, işleyiş mantığını ve tasarım detaylarını içermektedir. Bu metni bir AI aracına vererek uygulamanın geliştirilmesini veya hata düzeltmesini sağlayabilirsiniz.

---

## 1. UYGULAMA AMACI VE VİZYONU
Smart QR Pro, herhangi bir sektördeki QR/Barkod etiketli ürünlerin karmaşık teknik detaylarını anında görüntülemek için tasarlanmış bir **çalışan odaklı** ürün tanımlama sistemidir. Yeni çalışanların ürünleri hızlıca tanıması için optimize edilmiştir. Statik bir katalog yerine, Firebase bulut tabanlı ve dinamik olarak değişebilen bir veri yapısı sunar.

**Hedef Kullanıcı:** Şirket çalışanları (özellikle yeni başlayanlar)
**Kullanım Senaryosu:** QR kodu okutma veya ürün adıyla arama yaparak ürün görseli ve teknik detaylara erişim

---

## 2. TEKNİK MİMARİ (Flutter Stack)

### Temel Yapı
- **Framework:** Flutter (Stable channel)
- **Dil:** Dart
- **Mimari Desen:** Provider Pattern (State Management)
- **Platformlar:** Android + iOS (cross-platform)

### Bağımlılıklar
| Paket | Versiyon | Amaç |
|-------|---------|------|
| firebase_core | ^3.13.0 | Firebase başlatma |
| firebase_auth | ^5.5.4 | Anonim + Email/Password kimlik doğrulama |
| cloud_firestore | ^5.6.7 | Bulut veritabanı (smartqrflutter koleksiyonu) |
| mobile_scanner | ^7.0.2 | QR/Barkod tarama (ML Kit) |
| cached_network_image | ^3.4.1 | Görsel önbellekleme |
| csv | ^6.0.0 | CSV dosya ayrıştırma (`;` ayırıcı) |
| provider | ^6.1.4 | State yönetimi |
| google_fonts | ^6.2.1 | Outfit yazı tipi |
| shared_preferences | ^2.5.3 | Yerel anahtar-değer depolama |
| file_picker | ^9.2.1 | CSV dosya seçimi |

### Firebase Yapılandırması
- **Proje ID:** smartqr-flutterapp
- **Koleksiyon:** `smartqrflutter`
- **Auth:** Anonim (okuma) + Email/Password (yazma/admin)
- **Rules:** Anonim kullanıcılar okuyabilir, sadece email/password ile giriş yapmış kullanıcılar yazabilir

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /smartqrflutter/{itemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.firebase.sign_in_provider == "password";
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 3. DOSYA YAPISI

```
app_flutter/
├── lib/
│   ├── main.dart                        # Giriş noktası, Firebase init, Provider
│   ├── firebase_options.dart            # Firebase proje kimlik bilgileri
│   ├── theme/
│   │   └── app_theme.dart               # Burgundy Light/Dark tema, Google Fonts
│   ├── models/
│   │   └── product_model.dart           # Esnek ürün modeli (JSON properties)
│   ├── services/
│   │   └── firebase_service.dart        # Auth + Firestore CRUD + CSV batch upload
│   ├── providers/
│   │   └── product_provider.dart        # State yönetimi (ChangeNotifier)
│   └── screens/
│       ├── home_screen.dart             # Ana ekran (görsel odaklı, arama, detaylar)
│       ├── qr_scanner_screen.dart       # QR Tarayıcı (1.2s dwell time)
│       └── settings_screen.dart         # Admin giriş + CSV yükleme
├── android/
│   └── app/
│       ├── google-services.json         # Firebase Android config
│       └── src/main/AndroidManifest.xml # android:label="Smart QR Pro"
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist     # Firebase iOS config
└── assets/images/
    └── app_icon.png                     # Uygulama ikonu (smartqr5.png - turuncu)
```

---

## 4. FONKSİYONEL AYRINTILAR

### A. Ana Ekran (home_screen.dart)
- **Görsel Odaklı:** Ürün görseli ekranın büyük çoğunluğunu kaplar
- **InteractiveViewer:** Pinch-to-zoom, çift dokunuşla tam ekran, pan (sürükleme)
- **Arama:** Üst kısımda debounce'lu (300ms) arama çubuğu, ürün adı/kodu ile arama
- **FocusNode:** Klavye yalnızca ürün seçildiğinde kapanır, arama sırasında açık kalır
- **Detay Paneli:** Sağ alt köşedeki FAB butonu ile açılır/kapanır özellik listesi
- **FAB Bounce Animasyonu:** Ürün yüklendiğinde kullanıcıyı yönlendiren mikro-animasyon
- **Ürün Badge:** Görsel üzerinde sol üstte yarı saydam ürün adı gösterimi

### B. QR Tarayıcı (qr_scanner_screen.dart)
- **Motor:** mobile_scanner (Google ML Kit tabanlı)
- **Kararlılık Algoritması (Dwell Time):** QR kodun 1.0 saniye kadrajda kalması gerekir
- **Grace Period:** El titremesinde 150ms tolerans (kod kaybolursa hemen sıfırlamaz)
- **İlerleme Göstergesi:** Daire şeklinde ilerleme çizimi (CustomPainter)
- **Fener:** Merkezi flashlight butonu (toggle)
- **Overlay:** Yarı saydam koyu arka plan, merkezde tarama alanı kesiği

### C. Ayarlar (settings_screen.dart)
- **Admin Girişi:** Email/Password ile Firebase Auth (autocorrect kapalı)
- **CSV Yükleme:** Admin-only, file_picker ile dosya seçimi, `;` ayırıcı
- **Batch Commit:** 500'lük paketlerle Firestore'a toplu yazım
- **Veri Yenileme:** Tüm ürünleri Firestore'dan tekrar çekme
- **Doğrulama:** CSV başlıkları kontrol edilir, boş satırlar atlanır

### D. Veri Modeli (product_model.dart)
- **Sabit Alanlar:** id, type, series, itemName, qrText, imageUrl
- **Dinamik Özellikler:** CSV'deki diğer tüm sütunlar `properties` Map'ine kaydedilir
- **JSON Esnekliği:** Veritabanı şemasını değiştirmeden yeni özellikler eklenebilir
- **Sayısal Düzenleme:** `#`, `series`, `pattern`, `model`, `number` alanları 2 haneli format

### E. CSV Formatı
- **Ayırıcı:** `;` (noktalı virgül)
- **Başlık Satırı:** `#;id;type;series;itemName;pattern;color;model;...;qrText;imageUrl`
- **Zorunlu Alan:** `id` (Firestore document ID olarak kullanılır)
- **Görsel:** `imageUrl` alanı Cloudinary veya herhangi bir CDN URL'si olabilir

---

## 5. TASARIM ÖZELLİKLERİ

### Renk Paleti
| Renk | Hex | Kullanım |
|------|-----|----------|
| Burgundy | #800020 | Ana tema rengi (primary) |
| Burgundy Light | #A3324D | Koyu tema primary |
| Burgundy Dark | #5C0015 | Vurgu |
| Surface Light | #F8F4F4 | Açık mod arka plan |
| Surface Dark | #1A1A2E | Koyu mod arka plan |
| Card Dark | #16213E | Koyu mod kart |
| Accent Gold | #D4AF37 | Vurgu, fener aktif, ilerleme |

### Tipografi
- **Font:** Google Fonts - Outfit
- **Ağırlıklar:** w400 (normal), w500 (medium), w600 (semibold), w700 (bold)

### Tema
- **Material 3:** Aktif
- **Mod:** Sistem temasına göre otomatik Light/Dark geçiş
- **Kartlar:** 16px border radius, hafif gölge
- **Input:** 12px border radius, focused durumda 2px burgundy border

### İkon
- Uygulama ikonu: smartqr5.png (turuncu kutu üzerinde QR kod, koyu mavi arka plan)

---

## 6. BİLİNEN DURUMLAR VE NOTLAR
- Debug APK boyutu büyüktür (~70MB+), release build ile ~15-20MB'a düşer
- Debug modda uygulama yavaş açılır, release modda hızlıdır
- Uygulama açılışında Firebase anonymous auth otomatik yapılır
- Admin giriş sonrası, CSV yükleme aktif olur
- iOS build için macOS gereklidir

---

## 7. GELİŞTİRME NOTLARI (AI İÇİN)
1. **Firebase Firestore** yapısı `smartqrflutter` koleksiyonu üzerindedir
2. **JSON Properties** mantığı korunarak arayüzde dinamik tablolar oluşturulmalı
3. **mobile_scanner v7** API kullanılır (torchState ValueListenable yerine manual state)
4. **Provider pattern** ile state yönetimi yapılır (ChangeNotifier)
5. **Tüm Firebase işlemleri** ProductProvider üzerinden FirebaseService'e erişir
6. **CSV ayrıştırma** `csv` paketi ile `;` delimiter kullanılır

---
Bu projenin temel felsefesi: **"Esnek Veri, Sabit Performans"** ilkesidir.



Tasarım Ekranları klasördedir.
