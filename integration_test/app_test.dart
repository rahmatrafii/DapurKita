import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dapurkita/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live API: onboarding, category, detail and search', (
    tester,
  ) async {
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(finder, findsWidgets);
    }

    Future<void> capture(String name) async {
      debugPrint('Capturing $name');
      var done = false;
      final screenshot = binding
          .takeScreenshot(name)
          .whenComplete(() => done = true);
      // Android capture requests a new frame; keep the test pumping until it arrives.
      for (var i = 0; i < 100 && !done; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await screenshot.timeout(const Duration(seconds: 10));
    }

    app.main();
    await tester.pump(const Duration(milliseconds: 700));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 700));
    await capture('01-onboarding');
    await tester.ensureVisible(find.byKey(const Key('get-started')));
    await tester.tap(find.byKey(const Key('get-started')));
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(find.byKey(const Key('category-Chicken')));
    await waitFor(find.byTooltip('Cari resep'));
    await waitFor(find.text('Inspirasi untuk hari ini'));
    await tester.pump(const Duration(seconds: 2));
    await capture('02-home');

    await tester.ensureVisible(find.byKey(const Key('category-Chicken')));
    await tester.tap(find.byKey(const Key('category-Chicken')));
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(find.textContaining('resep · Chicken'));
    await tester.pump(const Duration(seconds: 2));
    await capture('03-category');

    final open = find
        .byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith('open-'),
        )
        .first;
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(find.text('Bahan & takaran'));
    await tester.pump(const Duration(seconds: 1));
    await capture('04-detail');
    await tester.ensureVisible(find.text('Bahan & takaran'));
    await capture('05-ingredients');
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, 1200),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.ensureVisible(find.byKey(const Key('category-all')));
    await tester.tap(find.byKey(const Key('category-all')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'zzzzzzzzzzzzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(find.textContaining('Resep tidak ditemukan.'));
    await capture('06-empty-search');
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(find.text('Inspirasi untuk hari ini'));
    expect(tester.takeException(), isNull);
  });
}
