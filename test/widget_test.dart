import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dapurkita/main.dart';
import 'package:dapurkita/models/meal.dart';
import 'package:dapurkita/services/meal_service.dart';

Map<String, dynamic> recipe({String id = '1', String category = 'Chicken'}) => {
  'idMeal': id,
  'strMeal': id == '1' ? 'Chicken Test' : 'Seafood Test',
  'strCategory': category,
  'strArea': 'Indonesia',
  'strMealThumb': 'https://example.com/meal.jpg',
  'strInstructions': 'Cook until ready.',
  'strIngredient1': ' Chicken ',
  'strMeasure1': '200 g',
  'strIngredient2': '',
  'strIngredient3': 'Salt',
  'strMeasure3': null,
};

http.Response jsonResponse(Object body) => http.Response(jsonEncode(body), 200);
http.Response categoriesResponse() => jsonResponse({
  'categories': [
    {'strCategory': 'Chicken'},
    {'strCategory': 'Seafood'},
    {'strCategory': 'Dessert'},
  ],
});
http.Response mealsResponse([List<Map<String, dynamic>>? meals]) =>
    jsonResponse({
      'meals': meals ?? [recipe()],
    });

MealService mockService({
  Future<http.Response> Function(http.Request)? handle,
}) => MealService(
  client: MockClient((request) async {
    if (handle != null) return handle(request);
    if (request.url.path.endsWith('categories.php')) {
      return categoriesResponse();
    }
    if (request.url.path.endsWith('filter.php')) {
      return mealsResponse([recipe(id: '2', category: 'Seafood')]);
    }
    if (request.url.queryParameters['s'] == 'missing') {
      return jsonResponse({'meals': null});
    }
    return mealsResponse();
  }),
);

Future<void> openHome(WidgetTester tester, MealService service) async {
  await tester.pumpWidget(MyApp(service: service));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('get-started')));
  await tester.tap(find.byKey(const Key('get-started')));
  await tester.pumpAndSettle();
}

void main() {
  test('model pairs ingredients, skips gaps, country fallback and invalid identity', () {
    final meal = Meal.fromJson(recipe());
    expect(meal.ingredients, ['200 g Chicken', 'Salt']);
    expect(meal.area, 'Indonesia');
    expect(
      Meal.fromJson({...recipe(), 'strArea': null, 'strCountry': 'Brazil'})
          .area,
      'Brazil',
    );
    expect(
      () => Meal.fromJson({'strMeal': 'Missing ID'}),
      throwsFormatException,
    );
  });

  test('service encodes search and converts successful data', () async {
    final service = mockService(
      handle: (request) async {
        expect(request.url.queryParameters['s'], 'chicken & rice');
        return mealsResponse();
      },
    );
    addTearDown(service.close);
    expect(
      (await service.search(' chicken & rice ')).single.name,
      'Chicken Test',
    );
  });

  test(
    'service loads API categories, filtered summaries and full detail',
    () async {
      final paths = <Uri>[];
      final service = mockService(
        handle: (request) async {
          paths.add(request.url);
          if (request.url.path.endsWith('categories.php')) {
            return categoriesResponse();
          }
          if (request.url.path.endsWith('filter.php')) {
            return mealsResponse([
              {
                'idMeal': '2',
                'strMeal': 'Fish Test',
                'strMealThumb': '',
                'strCountry': 'Brazil',
              },
            ]);
          }
          return mealsResponse([recipe(id: '2', category: 'Seafood')]);
        },
      );
      addTearDown(service.close);
      expect(await service.categories(), ['Chicken', 'Seafood', 'Dessert']);
      final summary = (await service.byCategory('Seafood')).single;
      expect(summary.category, 'Seafood');
      expect(summary.area, 'Brazil');
      expect(paths.last.queryParameters['c'], 'Seafood');
      expect((await service.detail(summary.id)).ingredients, isNotEmpty);
      expect(paths.last.queryParameters['i'], '2');
    },
  );

  test(
    'service handles empty, HTTP, malformed, network and timeout errors',
    () async {
      final responses = [
        () async => jsonResponse({'meals': null}),
        () async => http.Response('', 503),
        () async => http.Response('not json', 200),
        () async => jsonResponse({'wrong': []}),
        () async => jsonResponse({
          'meals': [42],
        }),
        () async => jsonResponse({'meals': {}}),
        () async => jsonResponse({
          'meals': [
            {'idMeal': 1},
          ],
        }),
        () async => throw http.ClientException('offline'),
        () async => throw TimeoutException('timeout'),
      ];
      for (var i = 0; i < responses.length; i++) {
        final service = mockService(handle: (_) => responses[i]());
        try {
          if (i == 0) {
            expect(await service.search('missing'), isEmpty);
          } else {
            await expectLater(
              service.search('test'),
              throwsA(isA<MealApiException>()),
            );
          }
        } finally {
          service.close();
        }
      }
      final service = mockService(
        handle: (_) async => jsonResponse({
          'categories': [
            {'strCategory': 42},
          ],
        }),
      );
      addTearDown(service.close);
      await expectLater(service.categories(), throwsA(isA<MealApiException>()));
      final missing = mockService(
        handle: (_) async => jsonResponse({'meals': null}),
      );
      addTearDown(missing.close);
      await expectLater(
        missing.detail('missing'),
        throwsA(isA<MealApiException>()),
      );
    },
  );

  testWidgets(
    'onboarding opens home, no bottom navigation, detail and search work',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = mockService();
      addTearDown(service.close);
      await tester.pumpWidget(MyApp(service: service));
      await tester.pumpAndSettle();
      expect(find.text('Mulai memasak'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('get-started')));
      await tester.tap(find.byKey(const Key('get-started')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Chicken Test'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('open-1')));
      await tester.tap(find.byKey(const Key('open-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bahan & takaran'));
      expect(find.text('200 g Chicken'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.textContaining('Resep tidak ditemukan.'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(find.text('Chicken Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'category selection clears search including selected category and All',
    (tester) async {
      final requests = <Uri>[];
      final service = mockService(
        handle: (request) async {
          requests.add(request.url);
          if (request.url.path.endsWith('categories.php')) {
            return categoriesResponse();
          }
          if (request.url.path.endsWith('filter.php')) {
            return mealsResponse([recipe(id: '2', category: 'Seafood')]);
          }
          return mealsResponse();
        },
      );
      addTearDown(service.close);
      await openHome(tester, service);
      await tester.enterText(find.byType(TextField), 'chicken');
      await tester.tap(find.byTooltip('Cari resep'));
      await tester.pumpAndSettle();
      expect(find.text('Chicken Test'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'unsubmitted draft');
      await tester.tap(find.byKey(const Key('category-Seafood')));
      await tester.pumpAndSettle();
      expect(find.text('Seafood Test'), findsOneWidget);
      expect(find.text('Chicken Test'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(requests.last.path, endsWith('filter.php'));
      expect(requests.last.queryParameters['c'], 'Seafood');
      await tester.enterText(find.byType(TextField), 'chicken');
      await tester.tap(find.byTooltip('Cari resep'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Resep tidak ditemukan.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('category-Seafood')));
      await tester.pumpAndSettle();
      expect(find.text('Seafood Test'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.enterText(find.byType(TextField), 'chicken');
      await tester.tap(find.byTooltip('Cari resep'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category-all')));
      await tester.pumpAndSettle();
      expect(find.text('Chicken Test'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(requests.last.path, endsWith('search.php'));
      expect(requests.last.queryParameters['s'], '');
      await tester.tap(find.byTooltip('Muat ulang resep'));
      await tester.pumpAndSettle();
      expect(
        requests.where((uri) => uri.path.endsWith('categories.php')).length,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading, API error, category retry and recipe retry work', (
    tester,
  ) async {
    final first = Completer<http.Response>();
    var searches = 0;
    var categories = 0;
    final service = mockService(
      handle: (request) async {
        if (request.url.path.endsWith('categories.php')) {
          categories++;
          return categories == 1
              ? http.Response('', 500)
              : categoriesResponse();
        }
        searches++;
        return searches == 1 ? first.future : mealsResponse();
      },
    );
    addTearDown(service.close);
    await tester.pumpWidget(MyApp(service: service));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('get-started')));
    await tester.tap(find.byKey(const Key('get-started')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    first.complete(http.Response('', 503));
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP 503'), findsOneWidget);
    await tester.tap(find.text('Kategori gagal dimuat. Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('category-Chicken')), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken Test'), findsOneWidget);
  });

  testWidgets('detail retry fetches full ingredients after a failed lookup', (
    tester,
  ) async {
    var lookups = 0;
    final service = mockService(
      handle: (request) async {
        if (request.url.path.endsWith('categories.php')) {
          return categoriesResponse();
        }
        if (request.url.path.endsWith('lookup.php') && ++lookups == 1) {
          return http.Response('', 500);
        }
        return mealsResponse();
      },
    );
    addTearDown(service.close);
    await openHome(tester, service);
    await tester.ensureVisible(find.byKey(const Key('open-1')));
    await tester.tap(find.byKey(const Key('open-1')));
    await tester.pumpAndSettle();
    expect(lookups, 1);
    await tester.drag(
      find.byKey(const Key('detail-scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Bahan & takaran'), findsOneWidget);
    expect(find.text('200 g Chicken'), findsOneWidget);
  });

  testWidgets(
    'narrow screen and large text remain scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = mockService();
      addTearDown(service.close);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 600),
              textScaler: TextScaler.linear(1.6),
            ),
            child: child!,
          ),
          home: MyApp(service: service),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('get-started')));
      await tester.tap(find.byKey(const Key('get-started')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
