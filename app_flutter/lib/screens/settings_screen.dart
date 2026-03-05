import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/product_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoginLoading = false;
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _loginError = 'Email ve şifre giriniz.';
      });
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _loginError = null;
    });

    try {
      final provider = context.read<ProductProvider>();
      await provider.firebaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin girişi başarılı!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
          _loginError = 'Giriş başarısız: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
        });
      }
    }
  }

  Future<void> _logout() async {
    final provider = context.read<ProductProvider>();
    await provider.firebaseService.signOut();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapıldı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAndUploadCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    // Try UTF-8 first, fallback to Latin1
    String csvContent;
    try {
      csvContent = await file.readAsString(encoding: utf8);
    } catch (_) {
      csvContent = await file.readAsString(encoding: latin1);
    }

    if (!mounted) return;

    // Show file info
    final lineCount = csvContent.split('\n').where((l) => l.trim().isNotEmpty).length;

    // Confirm upload
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Yükle'),
        content: Text(
          '${result.files.single.name}\n$lineCount satır bulundu.\nFirestore\'a yüklemek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final provider = context.read<ProductProvider>();
      final count = await provider.uploadCsv(csvContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count ürün başarıyla yüklendi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yükleme hatası: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _refreshProducts() async {
    final provider = context.read<ProductProvider>();
    await provider.fetchProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.products.length} ürün yenilendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isAdmin = provider.firebaseService.isAdminLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin Login Section
          _buildSectionTitle('Admin Girişi'),
          const SizedBox(height: 8),
          if (!isAdmin) ...[
            _buildLoginCard(),
          ] else ...[
            _buildAdminStatusCard(),
          ],

          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionTitle('Veri Yönetimi'),
          const SizedBox(height: 8),
          _buildDataCard(isAdmin, provider),

          const SizedBox(height: 24),

          // App Info
          _buildSectionTitle('Uygulama Bilgisi'),
          const SizedBox(height: 8),
          _buildInfoCard(provider),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 8),
              Text(
                _loginError!,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoginLoading ? null : _login,
              icon: _isLoginLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoginLoading ? 'Giriş yapılıyor...' : 'Giriş Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatusCard() {
    final provider = context.read<ProductProvider>();
    final user = provider.firebaseService.currentUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Girişi Aktif',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(bool isAdmin, ProductProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CSV Upload (Admin only)
            ListTile(
              leading: Icon(
                Icons.upload_file,
                color: isAdmin
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              title: const Text('CSV Yükle'),
              subtitle: Text(
                isAdmin
                    ? 'Firestore\'a CSV dosyası yükle'
                    : 'Admin girişi gerekli',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: isAdmin,
              onTap: isAdmin ? _pickAndUploadCsv : null,
            ),
            const Divider(height: 1),
            // Refresh
            ListTile(
              leading: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Verileri Yenile'),
              subtitle: Text('${provider.products.length} ürün mevcut'),
              trailing: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: provider.isLoading ? null : _refreshProducts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ProductProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Smart QR Pro'),
              subtitle: const Text('v1.0.1 - Evrensel Ürün Yönetim Sistemi'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.storage,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Veritabanı'),
              subtitle: Text('${provider.products.length} ürün kayıtlı'),
            ),
          ],
        ),
      ),
    );
  }
}
