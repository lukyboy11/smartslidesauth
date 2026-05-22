import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/api_config.dart';

class PresentationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> presentation;
  final List<Map<String, dynamic>> allPresentations;

  const PresentationDetailsScreen({
    super.key,
    required this.presentation,
    this.allPresentations = const [],
  });

  @override
  State<PresentationDetailsScreen> createState() =>
      _PresentationDetailsScreenState();
}

class _PresentationDetailsScreenState extends State<PresentationDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoadingPreview = true;

  static const String _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  InterstitialAd? _interstitialAd;
  final Dio _dio = Dio();

  late TabController _tabController;
  final List<String> _tabs = ['Aperçu', 'Détails', 'Similaires'];

  String get _title =>
      widget.presentation['title']?.toString() ?? 'Sans titre';
  String get _type => widget.presentation['type']?.toString() ?? 'PDF';
  String get _category =>
      widget.presentation['category']?.toString() ?? 'General';
  String get _fileId => widget.presentation['id']?.toString() ?? '';
  String get _webViewUrl => widget.presentation['url']?.toString() ?? '';
  String get _downloadUrl =>
      widget.presentation['downloadUrl']?.toString() ?? '';

  String get _displayName {
    return _title
        .replaceAll(RegExp(r'\.(pdf|pptx?|docx?)$', caseSensitive: false), '')
        .replaceAll('_', ' ');
  }

  // ✅ Proxy through your Vercel backend — no more 429
  String _getThumbnailUrl() {
    if (_fileId.isEmpty) return '';
    return '${ApiConfig.baseUrl}/api/thumbnail?id=$_fileId';
  }

  // ✅ Helper for related cards using their own ID
  String _getProxyThumbnailUrl(String fileId) {
    if (fileId.isEmpty) return '';
    return '${ApiConfig.baseUrl}/api/thumbnail?id=$fileId';
  }

  List<Map<String, dynamic>> get _relatedPresentations {
    return widget.allPresentations
        .where((p) =>
            p['id'] != widget.presentation['id'] &&
            p['category'] == _category)
        .take(6)
        .toList();
  }

  List<Map<String, dynamic>> get _allOtherPresentations {
    return widget.allPresentations
        .where((p) => p['id'] != widget.presentation['id'])
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initializeAds();
    _loadPreview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _interstitialAd?.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  Future<void> _loadPreview() async {
    setState(() => _isLoadingPreview = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoadingPreview = false);
  }

  Future<void> _initializeAds() async {
    if (!kIsWeb) _preloadInterstitialAd();
  }

  void _preloadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: _androidTestInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final directory = await getTemporaryDirectory();
      final sanitizedTitle = _title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final baseName = sanitizedTitle.replaceAll(
          RegExp(r'\.(pdf|pptx?|docx?)$', caseSensitive: false), '');
      final ext = _type == 'PDF' ? 'pdf' : 'pptx';
      final filePath = '${directory.path}/$baseName.$ext';

      // ✅ Use backend download route with virtual ID
      String dlUrl;
      if (_downloadUrl.isNotEmpty && _downloadUrl.startsWith('/api/')) {
        dlUrl = '${ApiConfig.baseUrl}$_downloadUrl';
      } else if (_downloadUrl.isNotEmpty) {
        dlUrl = _downloadUrl.contains('?')
            ? '$_downloadUrl&confirm=t'
            : '$_downloadUrl?confirm=t';
      } else if (_fileId.isNotEmpty) {
        dlUrl =
            'https://drive.google.com/uc?export=download&confirm=t&id=$_fileId';
      } else {
        dlUrl = _webViewUrl;
      }

      if (dlUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun lien de téléchargement disponible'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final response = await _dio.download(
        dlUrl,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => true,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      bool shouldUseFallback = false;

      if (response.statusCode != 200) {
        shouldUseFallback = true;
      }

      final file = File(filePath);
      if (!shouldUseFallback && await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 15) {
          final header =
              String.fromCharCodes(bytes.take(150)).toLowerCase();
          if (header.contains('<!doctype html') ||
              header.contains('<html')) {
            shouldUseFallback = true;
            await file.delete();
          }
        }
      }

      if (shouldUseFallback) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Redirection vers le navigateur pour finaliser le téléchargement.'),
              backgroundColor: context.appColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        await _launchUrl(dlUrl);
        return;
      }

      final result = await OpenFilex.open(filePath);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ouverture impossible: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Échec du téléchargement: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    final ad = _interstitialAd;
    if (ad == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Chargement de la publicité... Réessayez dans quelques secondes.'),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
      _preloadInterstitialAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitialAd();
        await _startDownload();
      },
      onAdFailedToShowFullScreenContent: (ad, _) async {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitialAd();
        await _startDownload();
      },
    );
    ad.show();
  }

  void _openFullscreenViewer() {
    if (_webViewUrl.isNotEmpty) {
      _launchUrl(_webViewUrl);
    } else if (_fileId.isNotEmpty) {
      _launchUrl('https://drive.google.com/file/d/$_fileId/view');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: appColors.surfaceContainerLow.withOpacity(0.7),
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: appColors.onSurfaceVariant),
            ),
            title: Text(
              'Smart Slides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
                color: appColors.onSurface,
              ),
            ),
           
          ),
          SliverToBoxAdapter(child: _buildPreviewSection(appColors)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabDelegate(
              child: Container(
                color: appColors.surface,
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  labelColor: appColors.primary,
                  unselectedLabelColor: appColors.onSurfaceVariant,
                  indicatorColor: appColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildTabContent(appColors),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(appColors),
    );
  }

  Widget _buildPreviewSection(AppPalette appColors) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isLoadingPreview)
            Container(
              color: appColors.surfaceContainerHigh,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: appColors.primary, strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(
                      'Chargement de l\'aperçu...',
                      style: TextStyle(
                          color: appColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildPreviewImage(appColors),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    appColors.surface.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getTypeColor(appColors).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getTypeIcon(), size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: appColors.surfaceContainerLow.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: appColors.outlineVariant.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ControlButton(
                      icon: Icons.visibility,
                      tooltip: 'Voir dans Google Drive',
                      appColors: appColors,
                      onPressed: _openFullscreenViewer,
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 1,
                        height: 20,
                        color: appColors.outlineVariant.withOpacity(0.3)),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: Icons.fullscreen,
                      tooltip: 'Plein écran',
                      appColors: appColors,
                      onPressed: _openFullscreenViewer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(AppPalette appColors) {
    // ✅ Using proxy URL — no more 429
    final thumbUrl = _getThumbnailUrl();
    if (thumbUrl.isNotEmpty) {
      return Image.network(
        thumbUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: appColors.surfaceContainerHigh,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: appColors.primary,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPreviewPlaceholder(appColors),
      );
    }
    return _buildPreviewPlaceholder(appColors);
  }

  Widget _buildPreviewPlaceholder(AppPalette appColors) {
    return Container(
      color: appColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getTypeIcon(),
                color: appColors.primary.withOpacity(0.3), size: 64),
            const SizedBox(height: 12),
            Text(
              'Aperçu non disponible',
              style: TextStyle(
                  color: appColors.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openFullscreenViewer,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ouvrir dans Google Drive'),
              style:
                  TextButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(AppPalette appColors) {
    switch (_tabController.index) {
      case 0:
        return _buildOverviewTab(appColors);
      case 1:
        return _buildDetailsTab(appColors);
      case 2:
        return _buildRelatedTab(appColors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(AppPalette appColors) {
    return Padding(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                label: _category.toUpperCase(),
                color: appColors.secondaryContainer,
                textColor: appColors.onSecondaryContainer,
              ),
              _TagChip(
                label: _type,
                color: appColors.surfaceContainerHighest,
                textColor: appColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _displayName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
              color: appColors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                    appColors: appColors,
                    icon: Icons.description_outlined,
                    label: 'Type',
                    value: _type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                    appColors: appColors,
                    icon: Icons.category_outlined,
                    label: 'Catégorie',
                    value: _category),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                    appColors: appColors,
                    icon: Icons.cloud_outlined,
                    label: 'Source',
                    value: 'Google Drive'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                    appColors: appColors,
                    icon: Icons.download_outlined,
                    label: 'Downloads',
                    value:
                        widget.presentation['downloads']?.toString() ?? '—'),
              ),
            ],
          ),
         
          
          if (_relatedPresentations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Du même type',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: appColors.onSurface),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(2);
                    setState(() {});
                  },
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: appColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _relatedPresentations.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final p = _relatedPresentations[index];
                  return _RelatedCard(
                    presentation: p,
                    allPresentations: widget.allPresentations,
                    getProxyUrl: _getProxyThumbnailUrl,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(AppPalette appColors) {
    return Padding(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMATIONS DU FICHIER',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: appColors.primary),
          ),
          const SizedBox(height: 16),
          _DetailRow(
              appColors: appColors,
              label: 'Nom du fichier',
              value: _title,
              icon: Icons.insert_drive_file_outlined),
          _DetailRow(
              appColors: appColors,
              label: 'Type de fichier',
              value: _type == 'PDF'
                  ? 'Document PDF (.pdf)'
                  : _type == 'PPT'
                      ? 'PowerPoint (.pptx)'
                      : 'Présentation',
              icon: Icons.description_outlined),
          _DetailRow(
              appColors: appColors,
              label: 'Catégorie',
              value: _category,
              icon: Icons.category_outlined),
          _DetailRow(
              appColors: appColors,
              label: 'Stockage',
              value: 'Google Drive',
              icon: Icons.cloud_outlined),
          if (_fileId.isNotEmpty)
          
          const SizedBox(height: 0),
         
        ],
      ),
    );
  }

  Widget _buildRelatedTab(AppPalette appColors) {
    final others = _allOtherPresentations;
    final categories = [
      'Tous',
      ...others
          .map((p) => p['category']?.toString() ?? 'General')
          .toSet()
    ];

    return _RelatedTabContent(
      key: const ValueKey('related'),
      appColors: appColors,
      presentations: others,
      categories: categories.toList(),
      allPresentations: widget.allPresentations,
      getProxyUrl: _getProxyThumbnailUrl,
    );
  }

  Widget _buildBottomBar(AppPalette appColors) {
    return Container(
      decoration: BoxDecoration(
        color: appColors.surfaceContainerLow.withOpacity(0.95),
        border: Border(
            top: BorderSide(color: appColors.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
       
       
       
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [appColors.primary, appColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: appColors.primary.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _handleDownload,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.download, color: appColors.onPrimary),
                    label: Text(
                      _isDownloading
                          ? '${(_downloadProgress * 100).toInt()}%'
                          : 'Télécharger',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: appColors.onPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: appColors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
           
           
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(AppPalette appColors) {
    switch (_type) {
      case 'PDF':
        return const Color(0xFFEF4444);
      case 'PPT':
        return const Color(0xFFFF6B35);
      default:
        return appColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (_type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'PPT':
        return Icons.present_to_all;
      default:
        return Icons.slideshow;
    }
  }
}

// ── Control Button ──
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final AppPalette appColors;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.appColors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: appColors.onSurfaceVariant),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: 22,
    );
  }
}

// ── Tag Chip ──
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _TagChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: textColor),
      ),
    );
  }
}

// ── Info Card ──
class _InfoCard extends StatelessWidget {
  final AppPalette appColors;
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.appColors,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: appColors.outlineVariant.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: appColors.primary),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: appColors.onSurfaceVariant.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: appColors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Action Tile ──
class _ActionTile extends StatelessWidget {
  final AppPalette appColors;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.appColors,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: appColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: appColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: appColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              appColors.onSurfaceVariant.withOpacity(0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: appColors.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Detail Row ──
class _DetailRow extends StatelessWidget {
  final AppPalette appColors;
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.appColors,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: appColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: appColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: appColors.onSurfaceVariant.withOpacity(0.7))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: appColors.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Link Tile ──
class _LinkTile extends StatelessWidget {
  final AppPalette appColors;
  final String label;
  final String url;
  final IconData icon;
  final VoidCallback onTap;

  const _LinkTile({
    required this.appColors,
    required this.label,
    required this.url,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: appColors.primary.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: appColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: appColors.primary)),
                  Text(
                      url.length > 45
                          ? '${url.substring(0, 45)}...'
                          : url,
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              appColors.onSurfaceVariant.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: appColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Related Card ──
class _RelatedCard extends StatefulWidget {
  final Map<String, dynamic> presentation;
  final List<Map<String, dynamic>> allPresentations;
  final String Function(String) getProxyUrl;

  const _RelatedCard({
    required this.presentation,
    required this.allPresentations,
    required this.getProxyUrl,
  });

  @override
  State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final title = widget.presentation['title']?.toString() ?? 'Sans titre';
    final displayName = title
        .replaceAll(RegExp(r'\.(pdf|pptx?|docx?)$', caseSensitive: false), '')
        .replaceAll('_', ' ');
    final type = widget.presentation['type']?.toString() ?? 'PDF';
    final category = widget.presentation['category']?.toString() ?? '';
    final fileId = widget.presentation['id']?.toString() ?? '';

    // ✅ Use proxy URL for related cards
    final proxyUrl = widget.getProxyUrl(fileId);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PresentationDetailsScreen(
              presentation: widget.presentation,
              allPresentations: widget.allPresentations,
            ),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (proxyUrl.isNotEmpty)
                        Image.network(
                          proxyUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: appColors.surfaceContainerHighest,
                            child: Icon(Icons.image,
                                color: appColors.onSurfaceVariant
                                    .withOpacity(0.3),
                                size: 32),
                          ),
                        )
                      else
                        Container(
                          color: appColors.surfaceContainerHighest,
                          child: Icon(Icons.slideshow,
                              color:
                                  appColors.onSurfaceVariant.withOpacity(0.3),
                              size: 32),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(type,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (category.isNotEmpty)
                Text(category.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: appColors.primary.withOpacity(0.7))),
              const SizedBox(height: 2),
              Text(displayName,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appColors.onSurface,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Related Tab with Filter ──
class _RelatedTabContent extends StatefulWidget {
  final AppPalette appColors;
  final List<Map<String, dynamic>> presentations;
  final List<String> categories;
  final List<Map<String, dynamic>> allPresentations;
  final String Function(String) getProxyUrl;

  const _RelatedTabContent({
    super.key,
    required this.appColors,
    required this.presentations,
    required this.categories,
    required this.allPresentations,
    required this.getProxyUrl,
  });

  @override
  State<_RelatedTabContent> createState() => _RelatedTabContentState();
}

class _RelatedTabContentState extends State<_RelatedTabContent> {
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filtered {
    var results = widget.presentations;
    if (_selectedCategory != 'Tous') {
      results = results
          .where((p) => p['category']?.toString() == _selectedCategory)
          .toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      results = results
          .where((p) =>
              (p['title']?.toString() ?? '').toLowerCase().contains(query))
          .toList();
    }
    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = widget.appColors;
    final filtered = _filtered;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                color: appColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14)),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: appColors.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(
                    color: appColors.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    color: appColors.onSurfaceVariant, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = widget.categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? appColors.primary
                          : appColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? appColors.onPrimary
                                : appColors.onSurfaceVariant)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${filtered.length} présentation${filtered.length != 1 ? 's' : ''} trouvée${filtered.length != 1 ? 's' : ''}',
            style: TextStyle(
                fontSize: 12,
                color: appColors.onSurfaceVariant.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off,
                        size: 48,
                        color: appColors.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('Aucun résultat',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: appColors.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((p) => _RelatedListItem(
                  presentation: p,
                  appColors: appColors,
                  allPresentations: widget.allPresentations,
                  getProxyUrl: widget.getProxyUrl,
                )),
        ],
      ),
    );
  }
}

// ── Related List Item ──
class _RelatedListItem extends StatelessWidget {
  final Map<String, dynamic> presentation;
  final AppPalette appColors;
  final List<Map<String, dynamic>> allPresentations;
  final String Function(String) getProxyUrl;

  const _RelatedListItem({
    required this.presentation,
    required this.appColors,
    required this.allPresentations,
    required this.getProxyUrl,
  });

  @override
  Widget build(BuildContext context) {
    final title = presentation['title']?.toString() ?? 'Sans titre';
    final displayName = title
        .replaceAll(RegExp(r'\.(pdf|pptx?|docx?)$', caseSensitive: false), '')
        .replaceAll('_', ' ');
    final type = presentation['type']?.toString() ?? 'PDF';
    final category = presentation['category']?.toString() ?? '';
    final fileId = presentation['id']?.toString() ?? '';

    // ✅ Use proxy URL for list items
    final proxyUrl = getProxyUrl(fileId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PresentationDetailsScreen(
              presentation: presentation,
              allPresentations: allPresentations,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: appColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 70,
                height: 56,
                child: proxyUrl.isNotEmpty
                    ? Image.network(
                        proxyUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: appColors.surfaceContainerHighest,
                          child: Icon(Icons.image,
                              size: 20,
                              color: appColors.onSurfaceVariant
                                  .withOpacity(0.3)),
                        ),
                      )
                    : Container(
                        color: appColors.surfaceContainerHighest,
                        child: Icon(Icons.slideshow,
                            size: 20,
                            color:
                                appColors.onSurfaceVariant.withOpacity(0.3)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: type == 'PDF'
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(type,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: type == 'PDF'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFFF6B35))),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(category,
                            style: TextStyle(
                                fontSize: 10,
                                color: appColors.onSurfaceVariant
                                    .withOpacity(0.6))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: appColors.onSurfaceVariant.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ── Sticky Tab Delegate ──
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabDelegate({required this.child});

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}