import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/alerts/app_alerts.dart';
import 'core/network/network_monitor.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'services/notification_service.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/dashboard/dashboard_viewmodel.dart';
import 'features/splash/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found or failed to load: $e');
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY'],
    );
  } catch (e) {
    debugPrint('Supabase init skipped: $e');
  }

  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  NetworkMonitor().startMonitoring();

  runApp(const BiteSizeApp());
}

class BiteSizeApp extends StatelessWidget {
  const BiteSizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
          ],
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'Bite Size',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeService.instance.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashView(),
          ),
        );
      },
    );
  }
}
