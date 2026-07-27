import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/debug/nav_debug_log.dart';
import '../core/security/go_router_auth_refresh.dart';
import '../core/security/session_security_gate.dart';
import '../features/authentication/presentation/models/account_created_args.dart';
import '../features/authentication/presentation/screens/account_created_screen.dart';
import '../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../features/authentication/presentation/screens/legal_document_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/calling/presentation/screens/call_history_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/contacts/presentation/screens/contacts_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/domain/entities/velix_public_profile.dart';
import '../features/profile/presentation/screens/my_profile_screen.dart';
import '../features/profile/presentation/screens/profile_preview_screen.dart';
import '../features/profile/presentation/screens/qr_scanner_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/time_capsule/domain/entities/story_owner_bucket.dart';
import '../features/time_capsule/presentation/screens/story_viewer_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const _publicPaths = <String>{
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.accountCreated,
    AppRoutes.terms,
    AppRoutes.privacy,
  };

  static final GoRouterAuthRefresh _authRefresh = GoRouterAuthRefresh(
    FirebaseAuth.instance.authStateChanges(),
  );

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _authRefresh,
    observers: [VelixNavObserver()],
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: AppRoutes.accountCreated,
        builder: (context, state) {
          final args = state.extra as AccountCreatedArgs;
          return AccountCreatedScreen(args: args);
        },
      ),

      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const MyProfileScreen(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (context, state) => const QrScannerScreen(),
      ),

      GoRoute(
        path: AppRoutes.profilePreview,
        builder: (context, state) {
          final profile = state.extra as VelixPublicProfile;
          return ProfilePreviewScreen(profile: profile);
        },
      ),

      GoRoute(
        path: AppRoutes.contacts,
        builder: (context, state) => const ContactsScreen(),
      ),

      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final data =
              state.extra as Map<String, dynamic>;

          return ChatScreen(
            conversationId:
                data['conversationId'] as String,
            currentUserId:
                data['currentUserId'] as String,
            otherUserId:
                data['otherUserId'] as String,
            userName:
                data['userName'] as String,
            profileImageUrl:
                data['profileImageUrl'] as String?,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.calls,
        builder: (context, state) => const CallHistoryScreen(),
      ),

      GoRoute(
        path: AppRoutes.timeCapsuleViewer,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          final rawBuckets = data['buckets'] as List<dynamic>;

          return StoryViewerScreen(
            buckets: rawBuckets
                .cast<StoryOwnerBucket>()
                .toList(),
            initialOwnerId: data['initialOwnerId'] as String,
          );
        },
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;
    final isPublic = _publicPaths.contains(loc);

    if (!loggedIn && !isPublic) {
      return AppRoutes.login;
    }

    // Require second-factor completion (when applicable) before protected routes.
    if (loggedIn &&
        !SessionSecurityGate.isSecondFactorVerified &&
        !isPublic) {
      return AppRoutes.splash;
    }

    if (loggedIn &&
        SessionSecurityGate.isSecondFactorVerified &&
        (loc == AppRoutes.login || loc == AppRoutes.register)) {
      return AppRoutes.home;
    }

    return null;
  }
}
