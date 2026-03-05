# MASTER PROMPT: Smart QR Pro - Evrensel Ürün Yönetim Sistemi (Flutter v1.0.2)

Bu doküman, "Smart QR Pro" Flutter uygulamasının tüm teknik mimarisini, işleyiş mantığını ve tasarım detaylarını içermektedir. Bu metni bir AI aracına vererek uygulamanın geliştirilmesini veya hata düzeltmesini sağlayabilirsiniz.

---

## 1. UYGULAMA AMACI VE VİZYONU
Smart QR Pro, herhangi bir sektördeki QR/Barkod etiketli ürünlerin karmaşık teknik detaylarını anında görüntülemek için tasarlanmış bir **çalışan odaklı** ürün tanımlama sistemidir. Yeni çalışanların ürünleri hızlıca tanıması için optimize edilmiştir.

**Hedef Kullanıcı:** Şirket çalışanları (özellikle yeni başlayanlar)
**Kullanım Senaryosu:** QR kodu okutma veya ürün adıyla arama yaparak ürün görseli ve teknik detaylara erişim
**Veri Akışı:**
- QR okutma → `qrText` alanı ile eşleşme
- Manuel arama → `itemName` alanı ile filtreleme
- Ürün görseli → `imageUrl` alanındaki URL'den (Cloudinary CDN)

---

## 2. TEKNİK MİMARİ (Flutter Stack)

### Temel Yapı
- **Framework:** Flutter (Stable channel)
- **Dil:** Dart
- **Mimari:** Provider Pattern + Offline-First
- **Platformlar:** Android + iOS

### Bağımlılıklar
| Paket | Amaç |
|-------|------|
| firebase_core, firebase_auth, cloud_firestore | Firebase altyapı |
| mobile_scanner ^7.0.2 | QR/Barkod tarama (ML Kit) |
| cached_network_image | Görsel önbellekleme |
| csv ^6.0.0 | CSV ayrıştırma (`;` ayırıcı) |
| provider | State yönetimi |
| google_fonts | Outfit yazı tipi |
| shared_preferences | Yerel anahtar-değer (sync zamanı) |
| path_provider | Yerel JSON dosya depolama |
| file_picker | CSV dosya seçimi |

### Firebase Yapılandırması
- **Proje ID:** smartqr-flutterapp
- **Koleksiyon:** `smartqrflutter`
- **Auth:** Anonim (okuma) + Email/Password (yazma/admin)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /smartqrflutter/{itemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.firebase.sign_in_provider == "password";
    }
    match /{document=**} { allow read, write: if false; }
  }
}
```

---

## 3. DOSYA YAPISI

```
app_flutter/lib/
├── main.dart                        # Giriş noktası, Firebase init, Provider
├── firebase_options.dart            # Firebase proje kimlik bilgileri
├── theme/app_theme.dart             # Burgundy Light/Dark tema
├── models/product_model.dart        # Esnek ürün modeli
├── services/
│   ├── firebase_service.dart        # Auth + Firestore CRUD + CSV upload
│   └── local_storage_service.dart   # Offline JSON depolama + sync kontrolü
├── providers/product_provider.dart  # State yönetimi (offline-first)
└── screens/
    ├── home_screen.dart             # Ana ekran (görsel + autocomplete arama)
    ├── qr_scanner_screen.dart       # QR Tarayıcı (1.2s dwell time)
    └── settings_screen.dart         # Admin giriş + CSV yükleme
```

---

## 4. VERİ MODELİ VE CSV FORMATI

### CSV Yapısı (`;` ayırıcı)

**Başlık satırı:**
```
#;id;type;series;itemName;pattern;color;model;feature4;feature5;size1;size2;size3;number;total;stock;qrText;imageUrl
```

**Örnek veriler:**
```
47;HALI-CAPE.TOWN-CPT.02.MULTY;HALI;CAPE.TOWN;CPT 02 MULTY;2;MULTY;;;;;;;;;10;HALI-CAPE.TOWN-CPT.02.MULTY;https://res.cloudinary.com/diktlnwin/image/upload/v1771926470/cape-town-cpt-02-multy-hav-toz-vermez--dcb1c4_ludmcx.jpg
54;HALI-COZY-CZY.03.GREY.BEIGE;HALI;COZY;CZY 03 GREY BEIGE;3;GREY.BEIGE;;;;;;;;;10;HALI-COZY-CZY.03.GREY.BEIGE;https://res.cloudinary.com/diktlnwin/image/upload/v1771926470/cozy-czy-03-grey-beige-hav-toz-vermez--363236_vamjh0.jpg
500;HALI-ZEN-ZEN.AMORF.01.BEIGE;HALI;ZEN;ZEN AMORF 01 BEIGE;;BEIGE;1;;;;;;;;10;HALI-ZEN-ZEN.AMORF.01.BEIGE;https://res.cloudinary.com/diktlnwin/image/upload/v1771926470/zen-amorf-01-beige.jpg
```

### Alan Açıklamaları
| Alan | Açıklama | Kullanım |
|------|----------|----------|
| `#` | Sıra numarası | Sadece referans |
| `id` | **Zorunlu** Benzersiz ürün ID | Firestore document ID |
| `type` | Ürün türü (HALI, KİLİM vb.) | Detay paneli |
| `series` | Ürün serisi | Detay paneli |
| `itemName` | **Ürün adı** | Manuel arama + görsel üstü badge |
| `pattern` | Desen kodu | Detay paneli |
| `color` | Renk | Detay paneli |
| `model` | Model numarası | Detay paneli |
| `qrText` | **QR kod metni** | QR tarama ile eşleşme |
| `imageUrl` | **Görsel URL** | Ürün görseli (Cloudinary CDN) |

> Dinamik alanlar: `feature4`, `feature5`, `size1-3`, `number`, `total`, `stock` gibi sabit alanlar dışındaki tüm sütunlar `properties` Map'ine kaydedilir.

---

## 5. FONKSİYONEL AYRINTILAR

### A. Offline-First Mimari
1. İlk açılış → Firebase'den tüm ürünler indirilir → JSON olarak cihaza kaydedilir
2. Sonraki açılışlar → Yerel JSON'dan anında yüklenir
3. 30 günde bir otomatik Firebase senkronizasyonu
4. Settings'te manuel "Verileri Güncelle" butonu

### B. Ana Ekran (home_screen.dart)
- **Görsel Odaklı:** Ürün görseli ekranın büyük çoğunluğunu kaplar
- **InteractiveViewer:** Pinch-to-zoom, çift dokunuşla tam ekran
- **Autocomplete Arama:** Overlay-based açılır liste, BÜYÜK HARF gösterim
  - Yazdıkça liste daralır, seçim yapınca klavye ve liste kapanır
  - 150ms debounce, yerel filtreleme (Firebase çağrısı yok)
- **Detay Paneli:** FAB butonu ile açılır/kapanır özellik listesi

### C. QR Tarayıcı (qr_scanner_screen.dart)
- **Dwell Time:** QR kodun 1.2 saniye kadrajda kalması gerekir
- **Grace Period:** 150ms tolerans
- **İlerleme:** Daire şeklinde CustomPainter çizimi
- **Fener:** Toggle butonu

### D. Ayarlar (settings_screen.dart)
- **Admin Girişi:** Email/Password (autocorrect kapalı, büyük harf yok)
- **CSV Yükleme:** UTF-8 BOM temizleme, fallback parser, detaylı hata mesajları
- **Veri Güncelle:** Firebase'den çek → yerele kaydet, son sync zamanı gösterilir

---

## 6. TASARIM ÖZELLİKLERİ

### Renk Paleti
| Renk | Hex | Kullanım |
|------|-----|----------|
| Burgundy | #800020 | Primary |
| Burgundy Light | #A3324D | Dark theme primary |
| Accent Gold | #D4AF37 | Vurgu, aktif fener, ilerleme |
| Surface Dark | #1A1A2E | Dark mode arka plan |

### Tipografi & Tema
- **Font:** Google Fonts - Outfit
- **Material 3** aktif, sistem temasına göre Light/Dark otomatik geçiş
- **İkon:** smartqr5.png (turuncu kutu, koyu mavi arka plan)

---

## 7. GELİŞTİRME NOTLARI (AI İÇİN)
1. `smartqrflutter` Firestore koleksiyonu kullanılır
2. `mobile_scanner v7` API (torchState → manual state tracking)
3. Provider pattern (ChangeNotifier) ile state yönetimi
4. CSV `;` delimiter, UTF-8 BOM temizleme zorunlu
5. Offline-first: `local_storage_service.dart` ile JSON dosya depolama
6. Tüm Firebase işlemleri `ProductProvider` → `FirebaseService` zinciri ile yapılır
7. Arama **yerel** filtreleme kullanır (Firebase çağrısı yapmaz)
8. Debug APK ~70MB+, release ~15-20MB (normal)
9. iOS build için macOS gereklidir

---
Bu projenin temel felsefesi: **"Esnek Veri, Sabit Performans"** ilkesidir.
