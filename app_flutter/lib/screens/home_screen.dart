import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';
import 'settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabBounce;
  bool _showDetails = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fabAnimationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onProductSelected(Product product) {
    context.read<ProductProvider>().selectProduct(product);
    _searchController.clear();
    _searchFocusNode.unfocus();
    context.read<ProductProvider>().searchProducts('');
    // Bounce FAB to hint at details
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
  }

  void _openScanner() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (product != null && mounted) {
      _onProductSelected(product);
    }
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart QR Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedProduct == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Search bar
              _buildSearchBar(provider),

              // Main content: product image OR search results
              Expanded(
                child: provider.searchResults.isNotEmpty
                    ? _buildSearchResults(provider)
                    : provider.selectedProduct != null
                        ? _buildProductView(provider.selectedProduct!)
                        : _buildEmptyState(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Details button (only when product selected)
              if (provider.selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ScaleTransition(
                    scale: _fabBounce,
                    child: FloatingActionButton.small(
                      heroTag: 'details',
                      onPressed: _toggleDetails,
                      backgroundColor: _showDetails
                          ? AppTheme.accentGold
                          : Theme.of(context).colorScheme.primary,
                      child: Icon(
                        _showDetails ? Icons.close : Icons.info_outline,
                      ),
                    ),
                  ),
                ),
              // QR Scanner button
              FloatingActionButton(
                heroTag: 'scanner',
                onPressed: _openScanner,
                child: const Icon(Icons.qr_code_scanner, size: 28),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ProductProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Ürün adı veya kodu ile ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.searchProducts('');
                    _searchFocusNode.unfocus();
                    setState(() {});
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (query) {
          setState(() {}); // Update suffix icon
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            provider.searchProducts(query);
          });
        },
      ),
    );
  }

  Widget _buildSearchResults(ProductProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final product = provider.searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            title: Text(
              product.itemName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${product.type} - ${product.series}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => _onProductSelected(product),
          ),
        );
      },
    );
  }

  Widget _buildProductView(Product product) {
    return Stack(
      children: [
        // Full-area product image
        GestureDetector(
          onDoubleTap: () => _showFullScreenImage(product),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (_, __, ___) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Görsel yüklenemedi',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Product name badge at the top
        Positioned(
          top: 8,
          left: 16,
          right: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.itemName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Full screen button
        Positioned(
          top: 8,
          right: 16,
          child: Material(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showFullScreenImage(product),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.fullscreen, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),

        // Details overlay panel
        if (_showDetails) _buildDetailsOverlay(product),
      ],
    );
  }

  Widget _buildDetailsOverlay(Product product) {
    final allProperties = <String, String>{
      'Tür': product.type,
      'Seri': product.series,
      ...product.properties.map(
        (key, value) => MapEntry(key, product.formatProperty(key, value)),
      ),
    };

    // Remove empty values
    allProperties.removeWhere((_, v) => v.isEmpty);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ürün Özellikleri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Properties list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: allProperties.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final entry = allProperties.entries.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageView(product: product),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Ürün Görüntülemek İçin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'QR kodu okutun veya yukarıdan arayın',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final Product product;

  const _FullScreenImageView({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          product.itemName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 6.0,
          child: CachedNetworkImage(
            imageUrl: product.imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image,
              size: 100,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
