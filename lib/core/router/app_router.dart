import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/deposit_screen.dart';
import '../../features/lobby/screens/lobby_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path:    '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path:    '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path:    '/lobby',
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path:    '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path:    '/wallet/deposit',
        builder: (context, state) => const DepositScreen(),
      ),
      GoRoute(
        path:    '/game/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return GameScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path:    '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],
  );
});