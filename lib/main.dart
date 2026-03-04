import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'services/settings_service.dart';
import 'screens/admin/admin_console_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/dashboard/host_dashboard_screen.dart';
import 'screens/dashboard/notifications_screen.dart';
import 'screens/dashboard/privacy_security_screen.dart';
import 'screens/dashboard/profile_screen.dart';
import 'screens/dashboard/resident_dashboard_screen.dart';
import 'screens/settings/app_appearance_screen.dart';
import 'screens/settings/app_info_screen.dart';
import 'screens/settings/data_export_screen.dart';
import 'screens/settings/emergency_contacts_screen.dart';
import 'screens/settings/language_region_screen.dart';
import 'screens/settings/notification_preferences_screen.dart';
import 'screens/settings/support_screen.dart';
import 'screens/entry/auth_choice_screen.dart';
import 'screens/entry/login_screen.dart';
import 'screens/entry/register_screen.dart';
import 'screens/entry/role_selection_screen.dart';
import 'screens/entry/splash_screen.dart';
import 'screens/setup/awaiting_access_screen.dart';
import 'screens/setup/host_setup_screen.dart';
import 'screens/setup/resident_join_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.init();
  await PushNotificationService.instance.init();
  await SettingsService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: SettingsService.instance.notifier,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Barivara',
          theme: AppTheme.light(visualDensity: settings.visualDensity),
          darkTheme: AppTheme.dark(visualDensity: settings.visualDensity),
          themeMode: settings.themeMode,
          builder: (context, child) {
            final data = MediaQuery.of(context);
            return MediaQuery(
              data: data.copyWith(textScaleFactor: settings.textScale),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.authChoice: (_) => const AuthChoiceScreen(),
            AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.hostSetup: (_) => const HostSetupScreen(),
            AppRoutes.residentJoin: (_) => const ResidentJoinScreen(),
            AppRoutes.awaitingAccess: (_) => const AwaitingAccessScreen(),
            AppRoutes.hostDashboard: (_) => const HostDashboardScreen(),
            AppRoutes.residentDashboard: (_) => const ResidentDashboardScreen(),
            AppRoutes.community: (_) => const CommunityScreen(),
            AppRoutes.notifications: (_) => const NotificationsScreen(),
            AppRoutes.profile: (_) => const ProfileScreen(),
            AppRoutes.privacySecurity: (_) => const PrivacySecurityScreen(),
            AppRoutes.notificationPreferences: (_) =>
                const NotificationPreferencesScreen(),
            AppRoutes.languageRegion: (_) => const LanguageRegionScreen(),
            AppRoutes.appAppearance: (_) => const AppAppearanceScreen(),
            AppRoutes.support: (_) => const SupportScreen(),
            AppRoutes.dataExport: (_) => const DataExportScreen(),
            AppRoutes.emergencyContacts: (_) =>
                const EmergencyContactsScreen(),
            AppRoutes.appInfo: (_) => const AppInfoScreen(),
            AppRoutes.adminConsole: (_) => const AdminConsoleScreen(),
          },
        );
      },
    );
  }
}
