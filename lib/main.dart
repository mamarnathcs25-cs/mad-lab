import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/screens/home_screen.dart';
import 'package:medapp/services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController();
  await controller.load();

  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MedApp',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
