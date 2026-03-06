# MASTER PROMPT: Smart QR Pro - QR Kod Ürün Yönetim Sistemi (Flutter v1.1.0)

Bu doküman, "Smart QR Pro" Flutter uygulamasının tüm teknik mimarisini, işleyiş mantığını ve tasarım detaylarını içermektedir. Bu metni bir AI aracına vererek uygulamanın geliştirilmesini veya hata düzeltmesini sağlayabilirsiniz.

---

## 1. UYGULAMA AMACI VE VİZYONU
Smart QR Pro, herhangi bir sektördeki QR/Barkod etiketli ürünlerin karmaşık teknik detaylarını anında görüntülemek için tasarlanmış bir **çalışan odaklı** ürün tanımlama sistemidir.

**Hedef Kullanıcı:** Şirket çalışanları (özellikle yeni başlayanlar)
**Kullanım Senaryosu:** QR kodu okutma veya ürün adıyla arama yaparak ürün görseli ve teknik detaylara erişim
**Veri Akışı:**
- QR okutma → `qrText` alanı ile eşleşme
- Manuel arama → `itemName` alanı ile yerel filtreleme
- Ürün görseli → `imageUrl` alanındaki URL'den (Cloudinary CDN)

---

## 2. TEKNİK MİMARİ

### Temel Yapı
- **Framework:** Flutter (Stable channel)
- **Dil:** Dart
- **Mimari:** Provider Pattern + Offline-First
- **Platformlar:** Android + iOS
- **Çift Dil:** TR/EN (AppLocalizations sınıfı)

### Firebase Projeleri (İKİ ADET)

| Proje | ID | Koleksiyon | Amaç |
|-------|-----|-----------|------|
| SmartQR | smartqr-flutterapp | `smartqrflutter` | Ürün verileri (CRUD) |
| MyData | mydata-81 | `mydata` / `mydata-81` | Geliştirici/Hakkında bilgisi (salt okunur) |

### SmartQR Firebase Rules
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

### MyData Firebase Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /mydata/{docId} {
      allow read: if true;   // Public read (login gerektirmez)
      allow write: if false; // Console'dan yönetilir
    }
  }
}
```

### Bağımlılıklar
| Paket | Amaç |
|-------|------|
| firebase_core, firebase_auth, cloud_firestore | Firebase altyapı (iki proje) |
| mobile_scanner ^7.0.2 | QR/Barkod tarama (ML Kit) |
| cached_network_image | Görsel önbellekleme |
| csv ^6.0.0 | CSV ayrıştırma (`;` ayırıcı) |
| provider | State yönetimi |
| google_fonts | Outfit yazı tipi |
| shared_preferences | Dil tercihi + sync zamanı |
| path_provider | Yerel JSON dosya depolama |
| file_picker | CSV dosya seçimi |

---

## 3. DOSYA YAPISI

```
app_flutter/lib/
├── main.dart                        # Giriş, Firebase init, dil yükleme
├── firebase_options.dart            # SmartQR Firebase kimlik bilgileri
├── theme/app_theme.dart             # Burgundy Light/Dark tema
├── l10n/app_localizations.dart      # TR/EN çeviri sistemi + property adları
├── models/product_model.dart        # Ürün modeli (2-digit formatting)
├── services/
│   ├── firebase_service.dart        # Auth + CRUD + CSV upload (BOM-safe)
│   ├── local_storage_service.dart   # Offline JSON + 30-gün sync
│   └── mydata_service.dart          # İkinci Firebase (Hakkında bilgisi)
├── providers/product_provider.dart  # State yönetimi (offline-first)
└── screens/
    ├── home_screen.dart             # Ana ekran (görsel + autocomplete)
    ├── qr_scanner_screen.dart       # QR Tarayıcı (center-matching)
    ├── settings_screen.dart         # Admin + CSV + Dil + Hakkında
    └── about_screen.dart            # Dinamik Hakkında sayfası
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
47;HALI-CAPE.TOWN-CPT.02.MULTY;HALI;CAPE.TOWN;CPT 02 MULTY;2;MULTY;;;;;;;;;10;HALI-CAPE.TOWN-CPT.02.MULTY;https://res.cloudinary.com/.../cape-town-cpt-02-multy.jpg
54;HALI-COZY-CZY.03.GREY.BEIGE;HALI;COZY;CZY 03 GREY BEIGE;3;GREY.BEIGE;;;;;;;;;10;HALI-COZY-CZY.03.GREY.BEIGE;https://res.cloudinary.com/.../cozy-czy-03-grey-beige.jpg
500;HALI-ZEN-ZEN.AMORF.01.BEIGE;HALI;ZEN;ZEN AMORF 01 BEIGE;;BEIGE;1;;;;;;;;10;HALI-ZEN-ZEN.AMORF.01.BEIGE;https://res.cloudinary.com/.../zen-amorf-01-beige.jpg
```

### Alan Açıklamaları
| Alan | TR Görünüm | Açıklama |
|------|-----------|----------|
| `id` | — | **Zorunlu** Firestore document ID |
| `type` | TÜR | Ürün türü |
| `series` | SERİ | Ürün serisi |
| `itemName` | — | Manuel arama + badge |
| `pattern` | DESEN | Desen kodu |
| `color` | RENK | Renk |
| `model` | MODEL | Model numarası |
| `qrText` | — | QR tarama eşleşmesi |
| `imageUrl` | — | Ürün görseli URL |

> Sabit alanlar dışındaki tüm CSV sütunları `properties` Map'ine kaydedilir. Tek karakterli sayısal değerler 01, 02 şeklinde gösterilir.

---

## 5. FONKSİYONEL AYRINTILAR

### A. Offline-First Mimari
1. İlk açılış → Firebase'den indir → JSON olarak kaydet
2. Sonraki açılışlar → Yerelden anında yükle
3. 30 günde bir otomatik senkronizasyon
4. Settings'te manuel "Verileri Güncelle"

### B. QR Tarayıcı — Center Matching + scanWindow
- `MobileScanner.scanWindow` parametresi ile native ML Kit seviyesinde tarama alanı sınırlaması
- Kare alanın DIŞINDA kalan QR kodlar hiç algılanmaz
- Alan içinde birden fazla QR varsa: merkeze en yakın seçilir (Öklid mesafesi)
- **Dwell time:** 1.0 saniye, **Grace period:** 400ms (el titremesi toleransı)
- Daire şeklinde ilerleme animasyonu (CustomPainter)

### C. Autocomplete Arama
- Overlay-based dropdown, BÜYÜK HARF gösterim
- Yazdıkça yerel filtreleme (Firebase çağrısı yok)
- Seçince klavye + liste kapanır, 150ms debounce

### D. Hakkında Sayfası (MyData Firebase)
- İkinci Firebase projesi (mydata-81) okunur
- `MyData/mydata-81` dökümanındaki tüm alanlar dinamik gösterilir
- Alan sırası: name → company → web → email → phone → address → diğerleri
- Boş alanlar gizlenir, yeni alan ekleyince otomatik görünür
- Firebase Console'dan içerik değiştirilebilir (uygulama güncellemesi gerekmez)

### E. Çift Dil Desteği (TR/EN)
- `AppLocalizations` sınıfı ile merkezi çeviri
- Settings'te SegmentedButton dil seçici
- SharedPreferences ile kalıcı dil tercihi
- Dil değişince tüm ekranlar yenilenir
- Özellik alan adları da çevrili (pattern→DESEN, color→RENK)

### F. CSV Yükleme (BOM-Safe)
- UTF-8 BOM karakteri karakter bazlı temizleme
- Case-insensitive header arama
- Fallback: manual split parser
- 500'lük batch Firestore yazımı

---

## 6. TASARIM ÖZELLİKLERİ

### Renk Paleti
| Renk | Hex | Kullanım |
|------|-----|----------|
| Burgundy | #800020 | Primary |
| Burgundy Light | #A3324D | Dark theme |
| Accent Gold | #D4AF37 | Vurgu, aktif fener |
| Surface Dark | #1A1A2E | Dark mode arka plan |

### Tema
- **Material 3**, Google Fonts - Outfit
- Sistem temasına göre otomatik Light/Dark
- İkon: smartqr5.png (turuncu kutu, koyu mavi arka plan)

---

## 7. BUILD VE DAĞITIM

### APK Adlandırma
- `SmartQRPro-v{version}-{buildType}.apk` (Gradle'da otomatik)
- Örnek: `SmartQRPro-v1.1.0-release.apk`

### Release Build
- Keystore: `android/smartqr-release.jks` (RSA 2048, 10000 gün)
- Signing config: `android/key.properties` (gitignore'da)
- R8 minification: kapalı (uyumluluk için)

---

## 8. GELİŞTİRME NOTLARI (AI İÇİN)
1. İKİ Firebase projesi kullanılır: SmartQR (ürünler) + MyData (hakkında)
2. `mobile_scanner v7` — `scanWindow` ile native tarama alanı sınırlaması
3. Provider + ChangeNotifier state yönetimi
4. CSV `;` delimiter, BOM temizleme zorunlu
5. Offline-first: `local_storage_service.dart` (JSON)
6. Arama yerel filtreleme (Firebase çağrısı yapmaz)
7. i18n: `app_localizations.dart` (TR/EN string + property name çeviri)
8. Görsel cache: `cached_network_image` — ilk indirmeden sonra yerel diskten
9. iOS build için macOS gereklidir (GitHub Actions alternatif)

---
Felsefe: **"Esnek Veri, Sabit Performans"**
