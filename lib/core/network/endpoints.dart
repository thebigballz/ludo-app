class Endpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login    = '/auth/login';
  static const String logout   = '/auth/logout';

  // Wallet
  static const String walletBalance     = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String deposit           = '/wallet/deposit';
  static const String withdraw          = '/wallet/withdraw';

  // Games
  static const String games     = '/games';
  static const String joinGame  = '/games/join';
  static const String gameResult = '/games/result';
  static const String leaderboard = '/leaderboard';
  static String leaveGame(int gameId) => '/games/$gameId/leave';
}