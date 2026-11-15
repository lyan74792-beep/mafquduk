// Public item browsing and search screen with type, category, and pagination (AppRoutes.browseItems).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/lookup_dropdown.dart';
import '../../data/models/item_summary.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/lookup_repository.dart';

class BrowseItemsScreen extends StatefulWidget {
  const BrowseItemsScreen({super.key});

  @override
  State<BrowseItemsScreen> createState() => _BrowseItemsScreenState();
}

class _BrowseItemsScreenState extends State<BrowseItemsScreen> {
  final _repo = ItemRepository();
  final _lookupRepo = LookupRepository();
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  List<String> _categories = const [];
  String _type = 'all';
  String _category = '';
  List<ItemSummary> _items = const [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadLookups();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final lookups = await _lookupRepo.load();
      if (!mounted) return;
      setState(() => _categories = lookups.categories);
    } catch (_) {
      // Categories filter remains with the "All" option if lookups fail.
    }
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final res = await _repo.browse(
        type: _type,
        category: _category,
        query: _searchController.text,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _page = res.page;
        _hasMore = res.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final res = await _repo.browse(
        type: _type,
        category: _category,
        query: _searchController.text,
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...res.items];
        _page = res.page;
        _hasMore = res.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showSnack(context, t('itemsLoadMoreError'), isError: true);
    }
  }

  void _onTypeSelected(String type) {
    if (_type == type) return;
    setState(() => _type = type);
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final allCategoriesLabel = t('itemsAllCategories');
    final dropdownOptions = <String>[allCategoriesLabel, ..._categories];
    final selectedDropdownValue = _category.isEmpty ? allCategoriesLabel : _category;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsBrowseTitle')),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadFirstPage(),
                  decoration: InputDecoration(
                    hintText: t('itemsSearchHint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune_outlined, color: AppColors.govGreen),
                      onPressed: _loadFirstPage,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypeChoiceChip(
                        label: t('itemsFilterAll'),
                        selected: _type == 'all',
                        onSelected: () => _onTypeSelected('all'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChoiceChip(
                        label: t('itemsFilterLost'),
                        selected: _type == 'lost',
                        onSelected: () => _onTypeSelected('lost'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChoiceChip(
                        label: t('itemsFilterFound'),
                        selected: _type == 'found',
                        onSelected: () => _onTypeSelected('found'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                LookupDropdown(
                  label: t('itemsCategoryFilterLabel'),
                  options: dropdownOptions,
                  value: selectedDropdownValue,
                  icon: Icons.category_outlined,
                  validator: (_) => null,
                  onChanged: (v) {
                    final next = (v == null || v == allCategoriesLabel) ? '' : v;
                    if (_category == next) return;
                    setState(() => _category = next);
                    _loadFirstPage();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          Expanded(
            child: _buildListBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return MessageView(
        icon: Icons.cloud_off_outlined,
        text: errorText(_error),
        actionLabel: t('retry'),
        onAction: _loadFirstPage,
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            MessageView(
              icon: Icons.search_off_outlined,
              text: t('itemsEmptyBrowse'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[index];
          return ItemCard(
            item: item,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.itemDetails,
              arguments: item,
            ),
          );
        },
      ),
    );
  }
}

class _TypeChoiceChip extends StatelessWidget {
  const _TypeChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.govGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.govGreen,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      side: const BorderSide(color: AppColors.govGreen),
      onSelected: (_) => onSelected(),
    );
  }
}
