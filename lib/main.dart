import 'core/alerts/toast.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'core/theme/activity_packs.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_view.dart';
import 'features/dashboard/dashboard_view.dart';
import 'features/splash/splash_view.dart';
import 'services/identity_service.dart';
import 'services/supabase_target.dart';
import 'services/analytics_service.dart';
import 'core/widgets/screen_name.dart';
import 'core/widgets/neo_progress_bar.dart';
import 'core/theme/app_colors.dart';
import 'core/network/network_monitor.dart';
import 'features/auth/auth_viewmodel.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/dashboard/dashboard_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clarity_flutter/clarity_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found or failed to load: $e');
  }

  await PackService.instance.load();

  final target = SupabaseTarget.forPack(PackService.instance.pack);
  try {
    debugPrint(
      '🔌 [SUPABASE] Connecting to ${target.name} database (${target.url})',
    );
    await Supabase.initialize(url: target.url, publishableKey: target.anonKey);
  } catch (e) {
    debugPrint('Supabase init skipped: $e');
  }

  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  try {
    await PushService.instance.init();
  } catch (e) {
    debugPrint('PushService init error: $e');
  }

  NetworkMonitor().startMonitoring();

  final clarity = _clarityConfig();
  Analytics.enabled = clarity != null;

  runApp(
    clarity == null
        ? const BiteSizeApp()
        : ClarityWidget(clarityConfig: clarity, app: const BiteSizeApp()),
  );
}

ClarityConfig? _clarityConfig() {
  if (!kReleaseMode) return null;

  final projectId = (dotenv.env['CLARITY_PROJECT_ID'] ?? '').trim();
  if (projectId.isEmpty) {
    debugPrint('📉 [CLARITY] No CLARITY_PROJECT_ID — session replay is off');
    return null;
  }

  return ClarityConfig(projectId: projectId, logLevel: LogLevel.None);
}

class BiteSizeApp extends StatefulWidget {
  const BiteSizeApp({super.key});

  @override
  State<BiteSizeApp> createState() => _BiteSizeAppState();
}

class _BiteSizeAppState extends State<BiteSizeApp> {
  String _packId = PackService.instance.pack.id;
  int _generation = 0;

  SupabaseTarget _target = SupabaseTarget.forPack(PackService.instance.pack);
  bool _switchingProject = false;

  @override
  void initState() {
    super.initState();
    PackService.instance.addListener(_onPackChanged);
  }

  @override
  void dispose() {
    PackService.instance.removeListener(_onPackChanged);
    super.dispose();
  }

  Future<void> _onPackChanged() async {
    final pack = PackService.instance.pack;
    if (pack.id == _packId) return;
    final next = SupabaseTarget.forPack(pack);

    if (next.sameProjectAs(_target)) {
      setState(() {
        _packId = pack.id;
        _generation++;
        newAppNavigatorKey();
      });
      return;
    }

    setState(() {
      _packId = pack.id;
      _switchingProject = true;
      _generation++;
      newAppNavigatorKey();
    });

    debugPrint('🔌 [SUPABASE] Rebinding ${_target.name} → ${next.name}');
    try {
      await Supabase.instance.dispose();
      await Supabase.initialize(url: next.url, publishableKey: next.anonKey);
      _target = next;
      IdentityService.instance.clear();
      await IdentityService.instance.restore();
    } catch (e) {
      debugPrint('❌ [SUPABASE] Rebind failed: $e');
      IdentityService.instance.clear();
    }

    if (!mounted) return;
    setState(() {
      _switchingProject = false;
      _generation++;
      newAppNavigatorKey();
    });
  }

  Widget get _entryScreen {
    if (_switchingProject) return const _ProjectSwitchScreen();
    if (_generation == 0) return const SplashView();
    return IdentityService.instance.isReady
        ? const DashboardView()
        : const AuthView();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return KeyedSubtree(
          key: ValueKey('generation:$_generation'),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthViewModel()),
              ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ],
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              navigatorObservers: [screenObserver],
              title: PackService.labels.activityName,
              debugShowCheckedModeBanner: false,
              themeMode: ThemeService.instance.themeMode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: MediaQuery(
                    data: media.copyWith(
                      textScaler: media.textScaler.clamp(
                        minScaleFactor: 0.9,
                        maxScaleFactor: 1.3,
                      ),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: _entryScreen,
            ),
          ),
        );
      },
    );
  }
}

class _ProjectSwitchScreen extends StatelessWidget {
  const _ProjectSwitchScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: NeoProgressBar(),
        ),
      ),
    );
  }
}
