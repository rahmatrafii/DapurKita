import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal.dart';

class MealApiException implements Exception {
  const MealApiException(this.message);
  final String message;
}

class MealService {
  MealService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> _get(
    String endpoint,
    Map<String, String> query,
  ) async {
    final uri = Uri.https(
      'www.themealdb.com',
      '/api/json/v1/1/$endpoint',
      query,
    );
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw MealApiException(
          'Server bermasalah (HTTP ${response.statusCode}). Coba lagi.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      return body;
    } on TimeoutException {
      throw const MealApiException(
        'Server terlalu lama merespons. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const MealApiException(
        'Tidak dapat terhubung. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const MealApiException('Data dari server tidak dapat diproses.');
    }
  }

  List<Map<String, dynamic>> _items(
    Map<String, dynamic> body,
    String key, {
    bool allowNull = false,
  }) {
    final items = body[key];
    if (allowNull && body.containsKey(key) && items == null) return [];
    if (items is! List || items.any((item) => item is! Map<String, dynamic>)) {
      throw const MealApiException('Data dari server tidak dapat diproses.');
    }
    return items.cast<Map<String, dynamic>>();
  }

  List<Meal> _meals(Map<String, dynamic> body, {String? category}) {
    try {
      return _items(body, 'meals', allowNull: true)
          .map(
            (item) => Meal.fromJson(
              category == null ? item : {...item, 'strCategory': category},
            ),
          )
          .toList();
    } on FormatException {
      throw const MealApiException(
        'Data resep dari server tidak dapat diproses.',
      );
    }
  }

  Future<List<Meal>> search(String query) async =>
      _meals(await _get('search.php', {'s': query.trim()}));

  Future<List<String>> categories() async {
    final items = _items(await _get('categories.php', {}), 'categories');
    return items
        .map((item) {
          final name = item['strCategory'];
          if (name is! String || name.trim().isEmpty) {
            throw const MealApiException(
              'Kategori dari server tidak dapat diproses.',
            );
          }
          return name.trim();
        })
        .toSet()
        .toList();
  }

  Future<List<Meal>> byCategory(String category) async =>
      _meals(await _get('filter.php', {'c': category}), category: category);

  Future<Meal> detail(String id) async {
    final meals = _meals(await _get('lookup.php', {'i': id}));
    if (meals.isEmpty) {
      throw const MealApiException('Resep ini sudah tidak tersedia.');
    }
    return meals.first;
  }

  void close() => _client.close();
}
