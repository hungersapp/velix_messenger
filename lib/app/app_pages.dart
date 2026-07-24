import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/contacts/presentation/screens/contacts_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/time_capsule/domain/entities/story_owner_bucket.dart';
import '../features/time_capsule/presentation/screens/story_viewer_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
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
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
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
}