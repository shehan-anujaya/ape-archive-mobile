import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/library/presentation/screens/library_browse_screen.dart';
import '../../features/library/presentation/screens/resource_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/forum/presentation/screens/forum_list_screen.dart';
import '../../features/forum/presentation/screens/question_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/resources/presentation/screens/pdf_viewer_screen.dart';
import '../../features/upload/presentation/screens/upload_screen.dart';
import 'app_navigation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AppNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // iOS-style slide transition
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryBrowseScreen(),
      ),
      GoRoute(
        path: '/resource/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ResourceDetailScreen(resourceId: id);
        },
      ),
      GoRoute(
        path: '/pdf',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'PDF';
          final url = state.uri.queryParameters['url'] ?? '';
          return PdfViewerScreen(title: title, streamingUrl: url);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/forum',
        builder: (context, state) => const ForumListScreen(),
      ),
      GoRoute(
        path: '/question/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuestionDetailScreen(questionId: id);
        },
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
