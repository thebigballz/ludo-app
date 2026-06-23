import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/wallet_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/wallet_repository.dart';
import '../../../core/errors/exceptions.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

class WalletState {
  final WalletModel? wallet;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final bool isDepositing;
  final bool isWithdrawing;
  final String? error;

  const WalletState({
    this.wallet,
    this.transactions  = const [],
    this.isLoading     = false,
    this.isDepositing  = false,
    this.isWithdrawing = false,
    this.error,
  });

  WalletState copyWith({
    WalletModel? wallet,
    List<TransactionModel>? transactions,
    bool? isLoading,
    bool? isDepositing,
    bool? isWithdrawing,
    String? error,
  }) {
    return WalletState(
      wallet:        wallet        ?? this.wallet,
      transactions:  transactions  ?? this.transactions,
      isLoading:     isLoading     ?? this.isLoading,
      isDepositing:  isDepositing  ?? this.isDepositing,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      error:         error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;

  WalletNotifier(this._repository) : super(const WalletState()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final wallet       = await _repository.getBalance();
      final transactions = await _repository.getTransactions();
      state = state.copyWith(
        wallet:       wallet,
        transactions: transactions,
        isLoading:    false,
      );
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        error:     'No internet connection.',
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
    }
  }

  Future<bool> deposit({
    required String phone,
    required double amount,
  }) async {
    state = state.copyWith(isDepositing: true, error: null);

    try {
      await _repository.deposit(phone: phone, amount: amount);
      state = state.copyWith(isDepositing: false);
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isDepositing: false, error: e.message);
      return false;
    } on NetworkException {
      state = state.copyWith(
        isDepositing: false,
        error:        'No internet connection.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isDepositing: false,
        error:        'Something went wrong.',
      );
      return false;
    }
  }

  Future<bool> withdraw({
    required String phone,
    required double amount,
  }) async {
    state = state.copyWith(isWithdrawing: true, error: null);

    try {
      await _repository.withdraw(phone: phone, amount: amount);
      // Reload balance after withdrawal
      await loadWallet();
      state = state.copyWith(isWithdrawing: false);
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isWithdrawing: false, error: e.message);
      return false;
    } on NetworkException {
      state = state.copyWith(
        isWithdrawing: false,
        error:         'No internet connection.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isWithdrawing: false,
        error:         'Something went wrong.',
      );
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.read(walletRepositoryProvider));
});