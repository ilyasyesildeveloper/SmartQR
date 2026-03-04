# Smart QR (v2.1.0)

Smart QR (eski adıyla CarpetQR), Android (Kotlin) ile geliştirilmiş, QR ve barkod okuma tabanlı evrensel bir envanter yönetim uygulamasıdır. Başlangıçta halı sektörü için tasarlanmış olsa da, v2.0.0 ile birlikte her türlü ürün grubuna uyarlanabilir "Evrensel" (Universal) bir mimariye taşınmıştır.

## 🚀 Öne Çıkan Özellikler

### Akıllı Tarama Sistemi
- **Google ML Kit:** Yüksek doğrulukta QR ve barkod tanıma.
- **Odaklanma Süresi (Dwell Time):** Yanlış okumaları önlemek için 1.2 saniyelik kararlı odaklanma mekanizması.
- **Akıllı Seçim:** Ekran merkezine en yakın kodu otomatik olarak önceliklendiren algoritma.
- **Kamera Kontrolleri:** Pinch-to-Zoom (çimdikle yakınlaştırma), Tap-to-Focus ve el feneri desteği.

### Kullanıcı Deneyimi (UX)
- **Onboarding (Karşılama):** Uygulamanın ilk kullanımında özelliklerin anlatıldığı bilgilendirme ekranı.
- **Hibrit Arama:** QR taramanın yanı sıra ürün ismi veya koduna göre hızlı arama.
- **Evrensel Formatlama:** Tüm sayısal alanların (Desen, Seri, Stok vb.) otomatik olarak en az iki haneli (örn: `01`, `05`) formatlanması.
- **Görsel Kontrolleri:** Ürün görsellerine çift tıklayarak yakınlaştırma ve sürükleme (Pan) desteği.
- **Detay Paneli:** Ürünün tüm ek özelliklerini (renk, ebat, seri vb.) görseli kapatmadan gösteren şık bir Bottom Sheet yapısı.

### Veri ve Yönetim
- **Otomatik Senkronizasyon:** Aylık periyotlarla veya ilk açılışta listenin Firebase üzerinden otomatik güncellenmesi.
- **Dinamik CSV Import:** Esnek sütun yapısı sayesinde herhangi bir CSV dosyasındaki ek özellikleri JSON formatında veritabanına aktarma.
- **Yerel Önbellek (Room):** Çevrimdışı kullanım için verilerin cihazda güvenli şekilde saklanması.
- **Yönetici Paneli:** E-posta/Parola korumalı, gizli erişimle ulaşılabilen yönetim merkezi.

## 🛠️ Kurulum ve Başlatma

1.  **Gereksinimler:** Android Studio (Bumblebee veya üzeri), JDK 17+, Android SDK 35.
2.  **Firebase:** `google-services.json` dosyasını `app/` dizinine ekleyin.
3.  **Çalıştırma:** Projeyi Android Studio ile açın ve Gradle sync sonrası cihazda çalıştırın.

## 🎓 Eğitim Odaklı Kod Yapısı
Bu proje, yeni öğrenen geliştiriciler için projenin her bir parçası detaylı Türkçe yorumlarla (DocStrings) süslenmiştir. KameraX kullanımından Firebase entegrasyonuna kadar her adım kod içinde adım adım açıklanmıştır.

## 📜 Lisans
Bu proje Apache License 2.0 ile lisanslanmıştır. (Copyright 2026 Ilyas YEŞİL)

---
*Smart QR: Karmaşıklığı tarayın, veriyi yönetin.*
