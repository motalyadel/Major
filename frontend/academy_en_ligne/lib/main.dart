import 'package:academy_en_ligne/features/admin/home/admin_home_page.dart';
import 'package:academy_en_ligne/features/admin/providers/local_provider.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart';
import 'package:academy_en_ligne/features/student/home/register_page.dart';
import 'package:academy_en_ligne/features/student/home/splash_screen.dart';
import 'package:academy_en_ligne/features/student/home/student_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:academy_en_ligne/core/utils/navigator.dart';
import 'package:academy_en_ligne/l10n/generated/app_localizations.dart';
import 'package:academy_en_ligne/features/admin/providers/local_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env["SUPABASE_URL"]!,
    anonKey: dotenv.env["SUPABASE_ANON_KEY"]!,
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    // ChangeNotifierProvider.value(value: AuthController()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(builder: (context, localeProvider, child) {
      return MaterialApp(
        title: 'LOCAL VIGGIES',
        debugShowCheckedModeBanner: false,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorKey: AppNavigator.globalKey,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const RegisterPage(),
          '/admin_home': (context) => const AdminHomePage(),
          '/student_home': (context) => const StudentHomePage(),
        },
      );
    });
  }
}
