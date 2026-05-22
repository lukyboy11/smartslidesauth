import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import '../../core/navigation/navigation_visibility_controller.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../details/presentation_details_screen.dart';

class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    required this.url,
    required this.thumbnail,
    this.downloadUrl = '',
  });

  final String id;
  final String name;
  final String url;
  final String thumbnail;
  final String downloadUrl;

  String get type {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.pptx') || lower.endsWith('.ppt')) return 'PPT';
    return 'Slides';
  }

  String get category {
    final lower = name.toLowerCase();
    if (lower.contains('micro') || lower.contains('bio')) {
      return 'Microbiology';
    }
    if (lower.contains('archi') || lower.contains('design')) {
      return 'Architecture';
    }
    if (lower.contains('fin') ||
        lower.contains('crypto') ||
        lower.contains('bank')) {
      return 'FinTech';
    }
    return 'General';
  }

  factory DriveFile.fromJson(Map<String, dynamic> json) {
    return DriveFile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sans nom',
      url: json['url']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': name,
      'type': type,
      'category': category,
      'imageUrl': thumbnail,
      'url': url,
      'downloadUrl': downloadUrl,
      'downloads': '—',
      'duration': '—',
      'timeAgo': '',
    };
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tout';

  // ── Data state ──
  List<DriveFile> _allFiles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // ── Pagination ──
  int _currentLimit = 10; // load 10 at a time
  int _totalCount = 0; // total files on server

  @override
  void initState() {
    super.initState();
    setHomeChromeVisible(true);
    _fetchPresentations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    setHomeChromeVisible(true);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  String _resolveBaseUrl() => ApiConfig.baseUrl;

  // ── Fetch with pagination support ──
  Future<void> _fetchPresentations({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      http.Response? response;
      Object? lastError;

      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final uri = Uri.parse(
            '${_resolveBaseUrl()}/api/templates'
            '?limit=$_currentLimit'
            '&t=${DateTime.now().millisecondsSinceEpoch}',
          );
          response = await http
              .get(uri, headers: ApiConfig.defaultHeaders)
              .timeout(const Duration(seconds: 45));
          break;
        } catch (e) {
          lastError = e;
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (response == null) {
        throw Exception(lastError ?? 'Aucune réponse du serveur.');
      }

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final rawData = json['data'] as List<dynamic>? ?? [];

      // ✅ Capture total from backend
      final total = json['total'] as int? ?? rawData.length;

      if (!mounted) return;

      setState(() {
        _allFiles = rawData
            .whereType<Map<String, dynamic>>()
            .map(DriveFile.fromJson)
            .toList();
        _totalCount = total;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Impossible de charger les présentations.\n'
            'Backend: ${_resolveBaseUrl()}\n'
            'Détail: $e\n'
            'Astuce: le serveur peut être en veille, réessaie dans 10-20 secondes.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // ── Load 10 more ──
  void _loadMore() {
    setState(() => _currentLimit += 10);
    _fetchPresentations(loadMore: true);
  }

  // ── Filters ──
  List<String> get _dynamicFilters {
    final types = _allFiles.map((f) => f.type).toSet().toList()..sort();
    return ['Tout', ...types];
  }

  List<DriveFile> get _filteredFiles {
    var results = _allFiles;

    if (_selectedFilter != 'Tout') {
      results = results.where((f) => f.type == _selectedFilter).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      results = results
          .where((f) => f.name.toLowerCase().contains(query))
          .toList();
    }

    return results;
  }

  // ── How many more are on the server ──
  int get _remainingCount => _totalCount - _allFiles.length;
  bool get _hasMore => _remainingCount > 0;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.surface,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final direction = notification.direction;

          if (direction == ScrollDirection.reverse) {
            setHomeChromeVisible(false);
          } else if (direction == ScrollDirection.forward) {
            setHomeChromeVisible(true);
          } else if (notification.metrics.pixels <= 0) {
            setHomeChromeVisible(true);
          }

          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: appColors.surfaceContainerLow,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              title: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.04,
                    color: appColors.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: 'Smart',
                      style: TextStyle(color: appColors.onSurface),
                    ),
                    TextSpan(
                      text: ' Slides',
                      style: TextStyle(color: appColors.primary),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _currentLimit = 10;
                            _totalCount = 0;
                          });
                          _fetchPresentations();
                        },
                  icon: Icon(CupertinoIcons.refresh, color: appColors.primary),
                ),
              ],
            ),

            // ── Search + Filters ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: appColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: appColors.onSurface,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher des présentations...',
                          hintStyle: TextStyle(
                            color: appColors.onSurfaceVariant.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: appColors.onSurfaceVariant,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: appColors.onSurfaceVariant,
                                    size: 18,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
                    if (!_isLoading && _errorMessage == null)
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _dynamicFilters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _dynamicFilters[index];
                            final isSelected = filter == _selectedFilter;
                            return _FilterChip(
                              label: filter,
                              isSelected: isSelected,
                              onTap: () =>
                                  setState(() => _selectedFilter = filter),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── File count info ──
            if (!_isLoading && _errorMessage == null && _allFiles.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '${_allFiles.length} présentations affichées sur $_totalCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

            // ── Main body ──
            _buildBody(),

            // ── Load More button ──
            if (!_isLoading && _errorMessage == null && _hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingMore ? null : _loadMore,
                      icon: _isLoadingMore
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: appColors.primary,
                              ),
                            )
                          : const Icon(Icons.expand_more_rounded),
                      label: Text(
                        _isLoadingMore
                            ? 'Chargement...'
                            : 'Voir plus ($_remainingCount restantes)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: appColors.primary,
                        side: BorderSide(
                          color: appColors.primary.withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── All loaded message ──
            if (!_isLoading &&
                _errorMessage == null &&
                _allFiles.isNotEmpty &&
                !_hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Center(
                    child: Text(
                      'Les $_totalCount présentations sont chargées ✓',
                      style: TextStyle(
                        fontSize: 12,
                        color: appColors.primary.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final appColors = context.appColors;

    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _SkeletonCard(),
            childCount: 6,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: appColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.wifi_slash,
                    size: 36,
                    color: appColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connexion impossible',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: appColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchPresentations,
                  icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final files = _filteredFiles;

    if (files.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: appColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.search,
                    size: 36,
                    color: appColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun résultat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: appColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'Aucune présentation ne correspond à\n"${_searchController.text}"'
                      : 'Aucune présentation de type "$_selectedFilter"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _selectedFilter = 'All');
                  },
                  child: const Text('Réinitialiser les filtres'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final file = files[index];
          return _PresentationCard(
            file: file,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PresentationDetailsScreen(
                    presentation: file.toMap(),
                    allPresentations: _allFiles.map((f) => f.toMap()).toList(),
                  ),
                ),
              );
            },
          );
        }, childCount: files.length),
      ),
    );
  }
}

// ── Filter Chip ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appColors.primary : appColors.secondaryContainer,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? appColors.onPrimary
                : appColors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

// ── Presentation Card ──
class _PresentationCard extends StatefulWidget {
  final DriveFile file;
  final VoidCallback onTap;

  const _PresentationCard({required this.file, required this.onTap});

  @override
  State<_PresentationCard> createState() => _PresentationCardState();
}

class _PresentationCardState extends State<_PresentationCard> {
  bool _isHovered = false;

  Color _getTypeColor(String type) {
    final appColors = context.appColors;
    switch (type) {
      case 'PDF':
        return appColors.primaryContainer;
      case 'PPT':
        return appColors.tertiaryContainer;
      case 'Slides':
        return appColors.secondaryContainer;
      default:
        return appColors.surfaceContainerHighest;
    }
  }

  Color _getTypeTextColor(String type) {
    final appColors = context.appColors;
    switch (type) {
      case 'PDF':
        return appColors.onPrimaryContainer;
      case 'PPT':
        return appColors.onTertiaryContainer;
      case 'Slides':
        return appColors.onSecondaryContainer;
      default:
        return appColors.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    // ✅ Use proxy thumbnail URL
    final thumbnailUrl = widget.file.id.isNotEmpty
        ? '${ApiConfig.baseUrl}/api/thumbnail?id=${widget.file.id}'
        : '';

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? appColors.surfaceContainerHighest
              : appColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl.isNotEmpty)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(appColors),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: appColors.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: appColors.primary,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _buildPlaceholder(appColors),
                    // Type Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(
                            widget.file.type,
                          ).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.file.type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getTypeTextColor(widget.file.type),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.file.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: appColors.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          _iconForType(widget.file.type),
                          size: 14,
                          color: appColors.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.file.type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: appColors.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          CupertinoIcons.link,
                          size: 14,
                          color: appColors.primary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Drive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: appColors.primary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppPalette appColors) {
    return Container(
      color: appColors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          CupertinoIcons.doc_richtext,
          color: appColors.onSurfaceVariant.withOpacity(0.3),
          size: 40,
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'PDF':
        return CupertinoIcons.doc_fill;
      case 'PPT':
        return CupertinoIcons.rectangle_stack_fill;
      default:
        return CupertinoIcons.play_rectangle_fill;
    }
  }
}

// ── Skeleton Card ──
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: appColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: appColors.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: appColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: appColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
