import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/product_provider.dart';
import '../l10n/app_localizations.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLanguageChanged;
  const SettingsScreen({super.key, this.onLanguageChanged});

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

  String _t(String key) => AppLocalizations.get(key);

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _loginError = _t('email_password_required'));
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
        setState(() => _isLoginLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('login_success')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
          _loginError = '${_t('login_failed')}: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
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
        SnackBar(
          content: Text(_t('logged_out')),
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
    String csvContent;
    try {
      csvContent = await file.readAsString(encoding: utf8);
    } catch (_) {
      csvContent = await file.readAsString(encoding: latin1);
    }

    if (!mounted) return;

    final lineCount = csvContent.split('\n').where((l) => l.trim().isNotEmpty).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('upload_confirm_title')),
        content: Text(
          '${result.files.single.name}\n$lineCount ${_t('lines_found')}\n${_t('upload_confirm_msg')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('upload')),
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
            content: Text('$count ${_t('upload_success')}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_t('upload_error')}: $e'),
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
          content: Text('${provider.products.length} ${_t('products_refreshed')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changeLanguage(String lang) async {
    AppLocalizations.setLocale(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    widget.onLanguageChanged?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isAdmin = provider.firebaseService.isAdminLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Admin Login
          _buildSectionTitle(_t('admin_login')),
          const SizedBox(height: 6),
          if (!isAdmin) _buildLoginCard() else _buildAdminStatusCard(),

          const SizedBox(height: 16),

          // Data Management
          _buildSectionTitle(_t('data_management')),
          const SizedBox(height: 6),
          _buildDataCard(isAdmin, provider),

          const SizedBox(height: 16),

          // Language
          _buildSectionTitle(_t('language')),
          const SizedBox(height: 6),
          _buildLanguageCard(),

          const SizedBox(height: 16),

          // App Info
          _buildSectionTitle(_t('app_info')),
          const SizedBox(height: 6),
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: _t('email'),
                prefixIcon: const Icon(Icons.email_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: _t('password'),
                prefixIcon: const Icon(Icons.lock_outline),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 6),
              Text(_loginError!, style: TextStyle(color: Colors.red[700], fontSize: 11)),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoginLoading ? null : _login,
              icon: _isLoginLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(_isLoginLoading ? _t('logging_in') : _t('login')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('admin_active'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                      ),
                      Text(user?.email ?? '',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(_t('logout')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(Icons.upload_file,
              color: isAdmin ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 22,
            ),
            title: Text(_t('csv_upload'), style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              isAdmin ? _t('csv_upload_desc') : _t('admin_required'),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            enabled: isAdmin,
            onTap: isAdmin ? _pickAndUploadCsv : null,
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(Icons.sync, color: Theme.of(context).colorScheme.primary, size: 22),
            title: Text(_t('refresh_data'), style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              provider.lastSyncTime != null
                  ? '${provider.products.length} ${_t('products_count')} | ${_t('last_sync')}: ${_formatDate(provider.lastSyncTime!)}'
                  : '${provider.products.length} ${_t('products_count')} | ${_t('not_synced')}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: provider.isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, size: 20),
            onTap: provider.isLoading ? null : _refreshProducts,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    final currentLang = AppLocalizations.locale;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.translate, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Text(_t('language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'tr', label: Text(_t('turkish'), style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: 'en', label: Text(_t('english'), style: const TextStyle(fontSize: 12))),
              ],
              selected: {currentLang},
              onSelectionChanged: (Set<String> newSelection) {
                _changeLanguage(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ProductProvider provider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 22),
            title: Text(_t('app_name'), style: const TextStyle(fontSize: 14)),
            subtitle: Text('v1.1.0 - ${_t('app_subtitle')}', style: const TextStyle(fontSize: 11)),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(Icons.storage, color: Theme.of(context).colorScheme.primary, size: 22),
            title: Text(_t('database'), style: const TextStyle(fontSize: 14)),
            subtitle: Text('${provider.products.length} ${_t('products_registered')}', style: const TextStyle(fontSize: 11)),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary, size: 22),
            title: Text(_t('about'), style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
