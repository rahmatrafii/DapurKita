import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../widgets/meal_image.dart';

class MealDetailPage extends StatefulWidget {
  const MealDetailPage({super.key, required this.meal, required this.service});
  final Meal meal;
  final MealService service;

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  late Future<Meal> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.service.detail(widget.meal.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Detail resep',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder<Meal>(
            future: _detail,
            builder: (context, snapshot) {
              final meal = snapshot.data ?? widget.meal;
              return ListView(
                key: const Key('detail-scroll'),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: MealImage(meal: meal),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(meal.category),
                        backgroundColor: green.withValues(alpha: 0.15),
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text(meal.area),
                        backgroundColor: pale,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Column(
                      children: [
                        Text(
                          snapshot.error is MealApiException
                              ? (snapshot.error as MealApiException).message
                              : 'Detail resep belum dapat dimuat.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => setState(() {
                            _detail = widget.service.detail(widget.meal.id);
                          }),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    )
                  else ...[
                    const Text(
                      'Bahan & takaran',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (meal.ingredients.isEmpty)
                      const Text('Daftar bahan belum tersedia.')
                    else
                      for (final ingredient in meal.ingredients)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  color: green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: const TextStyle(height: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: pale, thickness: 2),
                    ),
                    const Text(
                      'Cara memasak',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      meal.instructions,
                      style: const TextStyle(
                        color: ink,
                        height: 1.8,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Sumber: TheMealDB. Bahan dan petunjuk mengikuti bahasa asli penyedia data.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.7),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
