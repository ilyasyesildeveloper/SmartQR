/// Centralized string localizations for TR/EN support
class AppLocalizations {
  static String _currentLocale = 'tr';

  static String get locale => _currentLocale;

  static void setLocale(String locale) {
    _currentLocale = locale;
  }

  static String get(String key) {
    final map = _currentLocale == 'tr' ? _tr : _en;
    return map[key] ?? _tr[key] ?? key;
  }

  // Özellik alan adı çevirisi (CSV → ekran)
  static String propertyName(String key) {
    final map = _currentLocale == 'tr' ? _propertyNamesTr : _propertyNamesEn;
    return (map[key.toLowerCase()] ?? key).toUpperCase();
  }

  static const Map<String, String> _tr = {
    // App
    'app_name': 'Smart QR Pro',
    'app_subtitle': 'QR Kod Ürün Yönetim Sistemi',
    
    // Home
    'search_hint': 'Ürün adı ile ara...',
    'no_product': 'QR kod taratın veya ürün arayın',
    'product_not_found': 'Ürün bulunamadı',
    'details': 'Özellikler',
    
    // Scanner
    'scan_title': 'QR Tara',
    'focusing': 'Odaklanıyor...',
    'searching_product': 'Ürün aranıyor...',
    
    // Settings
    'settings': 'Ayarlar',
    'admin_login': 'Admin Girişi',
    'admin_active': 'Admin Girişi Aktif',
    'login': 'Giriş Yap',
    'logging_in': 'Giriş yapılıyor...',
    'logout': 'Çıkış Yap',
    'logged_out': 'Çıkış yapıldı.',
    'login_success': 'Admin girişi başarılı!',
    'login_failed': 'Giriş başarısız',
    'email': 'Email',
    'password': 'Şifre',
    'email_password_required': 'Email ve şifre giriniz.',
    'data_management': 'Veri Yönetimi',
    'csv_upload': 'CSV Yükle',
    'csv_upload_desc': 'Firestore\'a CSV dosyası yükle',
    'admin_required': 'Admin girişi gerekli',
    'refresh_data': 'Verileri Güncelle',
    'products_count': 'ürün',
    'last_sync': 'Son',
    'not_synced': 'Henüz senkronize edilmedi',
    'products_refreshed': 'ürün yenilendi.',
    'upload_confirm_title': 'CSV Yükle',
    'lines_found': 'satır bulundu.',
    'upload_confirm_msg': 'Firestore\'a yüklemek istiyor musunuz?',
    'cancel': 'İptal',
    'upload': 'Yükle',
    'upload_success': 'ürün başarıyla yüklendi!',
    'upload_error': 'Yükleme hatası',
    'app_info': 'Uygulama Bilgisi',
    'database': 'Veritabanı',
    'products_registered': 'ürün kayıtlı',
    'about': 'Hakkında',
    'language': 'Dil',
    'turkish': 'Türkçe',
    'english': 'English',
    
    // About
    'about_title': 'Hakkında',
    'about_app_desc': 'QR kod veya barkod taratarak ürün bilgilerine anında ulaşın. '
        'Manuel arama ile ürün adına göre de arayabilirsiniz.',
    'about_features_title': 'Özellikler',
    'about_feature_1': 'Akıllı QR/Barkod tarama (merkez eşleştirme)',
    'about_feature_2': 'Otomatik ürün tanımlama ve görsel gösterim',
    'about_feature_3': 'Yerel depolama ile çevrimdışı kullanım',
    'about_feature_4': 'Aylık otomatik güncelleme',
    'about_developer': 'Geliştirici',
    'about_version': 'Sürüm',
    'about_copyright': '© 2025 Tüm hakları saklıdır.',
  };

  static const Map<String, String> _en = {
    // App
    'app_name': 'Smart QR Pro',
    'app_subtitle': 'QR Code Product Management System',
    
    // Home
    'search_hint': 'Search by product name...',
    'no_product': 'Scan a QR code or search for a product',
    'product_not_found': 'Product not found',
    'details': 'Properties',
    
    // Scanner
    'scan_title': 'Scan QR',
    'focusing': 'Focusing...',
    'searching_product': 'Searching product...',
    
    // Settings
    'settings': 'Settings',
    'admin_login': 'Admin Login',
    'admin_active': 'Admin Login Active',
    'login': 'Login',
    'logging_in': 'Logging in...',
    'logout': 'Logout',
    'logged_out': 'Logged out.',
    'login_success': 'Admin login successful!',
    'login_failed': 'Login failed',
    'email': 'Email',
    'password': 'Password',
    'email_password_required': 'Enter email and password.',
    'data_management': 'Data Management',
    'csv_upload': 'Upload CSV',
    'csv_upload_desc': 'Upload CSV file to Firestore',
    'admin_required': 'Admin login required',
    'refresh_data': 'Refresh Data',
    'products_count': 'products',
    'last_sync': 'Last',
    'not_synced': 'Not synced yet',
    'products_refreshed': 'products refreshed.',
    'upload_confirm_title': 'Upload CSV',
    'lines_found': 'lines found.',
    'upload_confirm_msg': 'Upload to Firestore?',
    'cancel': 'Cancel',
    'upload': 'Upload',
    'upload_success': 'products uploaded successfully!',
    'upload_error': 'Upload error',
    'app_info': 'App Info',
    'database': 'Database',
    'products_registered': 'products registered',
    'about': 'About',
    'language': 'Language',
    'turkish': 'Türkçe',
    'english': 'English',
    
    // About
    'about_title': 'About',
    'about_app_desc': 'Instantly access product details by scanning QR codes or barcodes. '
        'You can also search by product name manually.',
    'about_features_title': 'Features',
    'about_feature_1': 'Smart QR/Barcode scanning (center matching)',
    'about_feature_2': 'Automatic product identification with visuals',
    'about_feature_3': 'Offline usage with local storage',
    'about_feature_4': 'Monthly automatic updates',
    'about_developer': 'Developer',
    'about_version': 'Version',
    'about_copyright': '© 2025 All rights reserved.',
  };

  // CSV alan adı çevirileri
  static const Map<String, String> _propertyNamesTr = {
    'pattern': 'DESEN',
    'color': 'RENK',
    'model': 'MODEL',
    'feature4': 'ÖZELLİK 4',
    'feature5': 'ÖZELLİK 5',
    'size1': 'EBAT 1',
    'size2': 'EBAT 2',
    'size3': 'EBAT 3',
    'number': 'NUMARA',
    'total': 'TOPLAM',
    'stock': 'STOK',
    'type': 'TÜR',
    'series': 'SERİ',
    '#': 'SIRA',
  };

  static const Map<String, String> _propertyNamesEn = {
    'pattern': 'PATTERN',
    'color': 'COLOR',
    'model': 'MODEL',
    'feature4': 'FEATURE 4',
    'feature5': 'FEATURE 5',
    'size1': 'SIZE 1',
    'size2': 'SIZE 2',
    'size3': 'SIZE 3',
    'number': 'NUMBER',
    'total': 'TOTAL',
    'stock': 'STOCK',
    'type': 'TYPE',
    'series': 'SERIES',
    '#': 'NO',
  };
}
