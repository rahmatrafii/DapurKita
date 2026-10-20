import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../widgets/meal_image.dart';
import 'meal_detail_page.dart';

class MealSearchPage extends StatefulWidget {
  const MealSearchPage({super.key, this.service});
  final MealService? service;

  @override
  State<MealSearchPage> createState() => _MealSearchPageState();
}

class _MealSearchPageState extends State<MealSearchPage> {
  final _searchController = TextEditingController();
  late final MealService _service;
  late Future<List<Meal>> _meals;
  late Future<List<String>> _categories;
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MealService();
    _categories = _service.categories();
    _meals = _loadMeals();
  }

  Future<List<Meal>> _loadMeals() async {
    final query = _query;
    final category = _category;
    if (query.isEmpty && category != null) return _service.byCategory(category);
    final meals = await _service.search(query);
    return category == null
        ? meals
        : meals.where((meal) => meal.category == category).toList();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    setState(() {
      _query = _searchController.text.trim();
      _meals = _loadMeals();
    });
  }

  void _selectCategory(String? category) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _query = '';
      _category = category;
      _meals = _loadMeals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: CustomScrollView(
            key: const Key('home-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            color: green,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'DapurKita',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Muat ulang resep',
                            onPressed: () {
                              _search();
                              setState(() {
                                _categories = _service.categories();
                              });
                            },
                            icon: const Icon(Icons.refresh, color: ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('recipe-search'),
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari resep',
                          prefixIcon: IconButton(
                            tooltip: 'Cari resep',
                            onPressed: _search,
                            icon: const Icon(Icons.search, color: ink),
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  icon: const Icon(Icons.close, color: ink),
                                  onPressed: () {
                                    _searchController.clear();
                                    _search();
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cari dalam bahasa Inggris, misalnya chicken atau pasta.',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<List<String>>(
                  future: _categories,
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              _categoryChip('Semua', null),
                              for (final category
                                  in snapshot.data ?? <String>[])
                                _categoryChip(category, category),
                            ],
                          ),
                        ),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        if (snapshot.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                _categories = _service.categories();
                              }),
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Kategori gagal dimuat. Coba lagi',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 24),
                    Divider(height: 8, thickness: 8, color: pale),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              FutureBuilder<List<Meal>>(
                future: _meals,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _message(
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Sedang mengambil resep...'),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _message(
                      Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 48,
                            color: muted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            snapshot.error is MealApiException
                                ? (snapshot.error as MealApiException).message
                                : 'Resep belum dapat dimuat.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _search,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  final meals = snapshot.data ?? <Meal>[];
                  if (meals.isEmpty) {
                    return _message(
                      const Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: muted),
                          SizedBox(height: 16),
                          Text(
                            'Resep tidak ditemukan.\nCoba nama atau kategori lainnya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.7),
                          ),
                        ],
                      ),
                    );
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            _query.isEmpty && _category == null
                                ? 'Inspirasi untuk hari ini'
                                : '${meals.length} resep${_category == null ? '' : ' · $_category'}',
                            style: const TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final scale = MediaQuery.textScalerOf(context)
                                .scale(1);
                            final columns =
                                constraints.crossAxisExtent < 300 || scale > 1.4
                                ? 1
                                : (constraints.crossAxisExtent / 260)
                                      .ceil()
                                      .clamp(2, 4);
                            final width =
                                (constraints.crossAxisExtent -
                                    22 * (columns - 1)) /
                                columns;
                            return SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _recipeCard(meals[index]),
                                childCount: meals.length,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 22,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: width + 132 * scale,
                                  ),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
                          child: Text(
                            'Resep dari TheMealDB · Bahan dan petunjuk mengikuti bahasa asli sumber.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _categoryChip(String label, String? value) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: ChoiceChip(
      key: ValueKey('category-${value ?? 'all'}'),
      label: Text(label),
      selected: _category == value,
      onSelected: (_) => _selectCategory(value),
      showCheckmark: false,
      selectedColor: green,
      backgroundColor: pale,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      labelStyle: TextStyle(
        color: _category == value ? onGreen : muted,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
  );

  Widget _message(Widget child) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Center(child: child),
    ),
  );

  Widget _recipeCard(Meal meal) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: pale,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.restaurant_menu, size: 16, color: ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meal.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('open-${meal.id}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MealDetailPage(meal: meal, service: _service),
              ),
            ),
            child: Semantics(
              button: true,
              label: 'Lihat resep ${meal.name}',
              child: MealImage(meal: meal),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        meal.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        meal.area,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: muted, fontSize: 13),
      ),
    ],
  );
}
