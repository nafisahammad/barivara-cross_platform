import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'theme.dart';
import 'screens/admin/admin_console_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/dashboard/host_dashboard_screen.dart';
import 'screens/dashboard/notifications_screen.dart';
import 'screens/dashboard/profile_screen.dart';
import 'screens/dashboard/resident_dashboard_screen.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barivara',
      theme: AppTheme.light(),
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
        AppRoutes.adminConsole: (_) => const AdminConsoleScreen(),
      },
    );
  }
}
