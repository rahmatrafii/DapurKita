class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.imageUrl,
    required this.instructions,
    required this.ingredients,
  });

  final String id;
  final String name;
  final String category;
  final String area;
  final String imageUrl;
  final String instructions;
  final List<String> ingredients;

  factory Meal.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value == null) return '';
      if (value is! String) {
        throw const FormatException('Atribut resep tidak valid.');
      }
      return value.trim();
    }

    final id = read('idMeal');
    final name = read('strMeal');
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Identitas resep tidak lengkap.');
    }
    final ingredients = <String>[];
    for (var i = 1; i <= 20; i++) {
      final ingredient = read('strIngredient$i');
      final measure = read('strMeasure$i');
      if (ingredient.isNotEmpty) {
        ingredients.add(measure.isEmpty ? ingredient : '$measure $ingredient');
      }
    }
    return Meal(
      id: id,
      name: name,
      category: read('strCategory').isEmpty
          ? 'Tanpa kategori'
          : read('strCategory'),
      area: read('strArea').isNotEmpty
          ? read('strArea')
          : read('strCountry').isNotEmpty
          ? read('strCountry')
          : 'Resep internasional',
      imageUrl: read('strMealThumb'),
      instructions: read('strInstructions').isEmpty
          ? 'Petunjuk memasak belum tersedia.'
          : read('strInstructions'),
      ingredients: ingredients,
    );
  }
}
