import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/mydata_service.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final MyDataService _myDataService = MyDataService();
  Map<String, dynamic> _developerData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _myDataService.fetchData();
    if (mounted) {
      setState(() {
        _developerData = data;
        _isLoading = false;
      });
    }
  }

  // Bilinen alan adları çevirisi
  String _fieldLabel(String key) {
    final labels = {
      'name': AppLocalizations.get('about_developer'),
      'company': AppLocalizations.locale == 'tr' ? 'Şirket' : 'Company',
      'email': 'Email',
      'web': 'Web',
      'phone': AppLocalizations.locale == 'tr' ? 'Telefon' : 'Phone',
      'address': AppLocalizations.locale == 'tr' ? 'Adres' : 'Address',
    };
    return labels[key.toLowerCase()] ?? key.toUpperCase();
  }

  IconData _fieldIcon(String key) {
    final icons = {
      'name': Icons.person,
      'company': Icons.business,
      'email': Icons.email,
      'web': Icons.language,
      'phone': Icons.phone,
      'address': Icons.location_on,
    };
    return icons[key.toLowerCase()] ?? Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.get;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('about_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Header
            _buildAppHeader(theme),
            const SizedBox(height: 20),

            // App Description
            _buildCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t('about_app_desc'),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Features
            _buildCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('about_features_title'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _featureItem(t('about_feature_1'), Icons.qr_code_scanner),
                    _featureItem(t('about_feature_2'), Icons.image),
                    _featureItem(t('about_feature_3'), Icons.offline_bolt),
                    _featureItem(t('about_feature_4'), Icons.sync),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Developer Info (from Firebase MyData)
            _buildDeveloperCard(theme),
            const SizedBox(height: 12),

            // Version + Copyright
            _buildCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('${t('about_version')}: 1.1.0',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('about_copyright'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.get('app_name'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          AppLocalizations.get('app_subtitle'),
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(ThemeData theme) {
    if (_isLoading) {
      return _buildCard(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    // Filter non-empty fields
    final fields = _developerData.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
        .toList();

    if (fields.isEmpty) {
      return _buildCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('İlyas YEŞİL tarafından geliştirildi.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (_myDataService.lastError != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Debug: ${_myDataService.lastError}',
                  style: TextStyle(fontSize: 10, color: Colors.red[300]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('about_developer'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...fields.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _fieldIcon(entry.key),
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fieldLabel(entry.key),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accentGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      child: child,
    );
  }
}
