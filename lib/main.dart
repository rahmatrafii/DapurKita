import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'screens/home_page.dart';
import 'services/meal_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.service});
  final MealService? service;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DapurKita',
    debugShowCheckedModeBanner: false,
    builder: (_, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: child!,
    ),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: green).copyWith(
        primary: green,
        onPrimary: onGreen,
        secondary: ink,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: onGreen,
          minimumSize: const Size(48, 56),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pale,
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: ink),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),
    ),
    home: OnboardingPage(service: service),
  );
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, this.service});
  final MealService? service;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Keep only the food collage from the supplied reference visible.
                    AspectRatio(
                      aspectRatio: 1125 / 1320,
                      child: ClipRect(
                        child: Image.asset(
                          'assets/images/onboarding.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.74),
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                      child: Column(
                        children: [
                          const Text(
                            'Mulai memasak',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Temukan resep favorit dan inspirasi\nuntuk hidanganmu hari ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              color: muted,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 34),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const Key('get-started'),
                              onPressed: () => Navigator.of(context)
                                  .pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          MealSearchPage(service: service),
                                    ),
                                  ),
                              child: const Text('Mulai sekarang'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
