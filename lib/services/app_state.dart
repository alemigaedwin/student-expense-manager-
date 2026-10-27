import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/note_model.dart';
import '../models/payment_method_model.dart';
import '../models/receipt_model.dart';
import '../models/reminder_model.dart';
import '../models/transaction_model.dart';
import 'default_data.dart';
import 'storage_service.dart';
import 'backend_service.dart';
import '../utils/app_colors.dart';

const _uuid = Uuid();

enum DateRangeMode { daily, weekly, monthly, yearly, custom, all }

class AppState extends ChangeNotifier {
  // ---- Raw collections (all accounts) ----
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<PaymentMethodModel> _paymentMethods = [];
  List<BudgetModel> _budgets = [];
  List<OverallBudgetModel> _overallBudgets = [];
  List<NoteModel> _notes = [];
  List<ReminderModel> _reminders = [];
  List<AccountModel> _accounts = [];

  String _currentAccountId = 'default';
  ThemeMode _themeMode = ThemeMode.light;
  bool _authenticated = false;
  bool _syncing = false;
  String? _syncError;
  DateTime? _lastSyncAt;
  Future<void> _syncQueue = Future<void>.value();
  final Map<String, String> _userSettings = <String, String>{};
  final Map<String, Set<String>> _pendingDeletions = <String, Set<String>>{};
  final Map<String, ReceiptInfo> _receipts = <String, ReceiptInfo>{};
  String _userDisplayName = '';
  bool get isSyncing => _syncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncAt => _lastSyncAt;

  ThemeMode get themeMode => _themeMode;
  bool get isAuthenticated => _authenticated;

  List<String> _recentCategoryIds = [];

  // Home screen widget visibility toggles
  bool showRecentTransactions = true;
  bool showPaymentMethod = true;
  bool showCategoryChart = true;
  bool showBudget = true;
  bool showTrend = true;

  // Selected date range for Home / Calendar / Transactions / Notebook
  DateRangeMode rangeMode = DateRangeMode.monthly;
  DateTime rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime rangeEnd = DateTime(
      DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  String currentAccountId() => _currentAccountId;

  // ---------------- Initialization ----------------
  Future<void> load() async {
    _accounts = [AccountModel(id: 'default', name: 'Income Expense')];
    _currentAccountId = _accounts.first.id;
    _themeMode = (StorageService.getSetting('theme_mode') ?? 'light') == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
    AppColors.darkMode = _themeMode == ThemeMode.dark;
    BackendService.token = StorageService.getSetting('backend_token');
    // A locally stored token is only a session hint. The backend must validate
    // it before any private screen is shown.
    _authenticated = false;
    final savedSyncAt = StorageService.getSetting('last_sync_at');
    _lastSyncAt = savedSyncAt == null ? null : DateTime.tryParse(savedSyncAt);
    _syncError = StorageService.getSetting('last_sync_error');
    if (_syncError != null && _syncError!.isEmpty) _syncError = null;

    _categories = [
      ...defaultIncomeCategories(),
      ...defaultExpenseCategories(),
    ];
    _paymentMethods = defaultPaymentMethods();
    _transactions = [];
    _budgets = [];
    _overallBudgets = [];
    _notes = [];
    _reminders = [];

    // Never show an offline copy of private records. The server is the source of
    // truth on both Android and web.
    if (BackendService.token != null && BackendService.token!.isNotEmpty) {
      try {
        final response = await BackendService.pullState();
        _applyRemoteState(Map<String, dynamic>.from(response['data'] ?? {}));
        _authenticated = true;
        StorageService.setSetting('logged_in', '1');
      } catch (_) {
        BackendService.token = null;
        StorageService.setSetting('backend_token', '');
        StorageService.setSetting('logged_in', '0');
        _clearCachedUserData();
      }
    }
    notifyListeners();
  }

  void saveHomeWidgetPrefs() {
    unawaited(syncNow());
  }

  // ---------------- Authentication ----------------
  bool hasRegisteredUser() => false;
  String? registeredEmail() => null;

  Future<bool> registerUser(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    if (cleanName.isEmpty || !cleanEmail.contains('@') || password.length < 6) {
      _syncError = 'Enter your name, a valid email, and a password of at least 6 characters.';
      notifyListeners();
      return false;
    }
    try {
      // Registration creates the server account only. The user must log in
      // separately before entering the main application.
      await BackendService.register(cleanName, cleanEmail, password);
      _syncError = null;
      return true;
    } catch (e) {
      _syncError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await BackendService.login(
        email.trim().toLowerCase(), password,
      );
      // Use only the authenticated account's server state. Do not silently
      // fall back to a local/demo login when the API rejects credentials.
      _clearCachedUserData();
      await _acceptBackendSession(response);
      _authenticated = true;
      _syncError = null;
      notifyListeners();
      unawaited(syncNow());
      return true;
    } catch (e) {
      _authenticated = false;
      _syncError = e.toString().replaceFirst('Exception: ', '');
      StorageService.setSetting('logged_in', '0');
      notifyListeners();
      return false;
    }
  }

  void _clearCachedUserData() {
    _transactions = [];
    _categories = [];
    _paymentMethods = [];
    _budgets = [];
    _overallBudgets = [];
    _notes = [];
    _reminders = [];
    _accounts = [];
    _currentAccountId = 'default';
    _userSettings.clear();
    _pendingDeletions.clear();
    _receipts.clear();
    _userDisplayName = '';
  }

  Future<void> _acceptBackendSession(Map<String, dynamic> response) async {
    final token = response['data']?['token']?.toString();
    if (token == null || token.isEmpty) throw Exception('No session token.');
    BackendService.token = token;
    StorageService.setSetting('backend_token', token);
    final user = Map<String, dynamic>.from(response['data']?['user'] ?? {});
    _userDisplayName = user['name']?.toString() ?? '';
    StorageService.setSetting('logged_in', '1');
    final remote = response['data']?['state'];
    if (remote is Map) {
      _applyRemoteState(Map<String, dynamic>.from(remote));
    }
  }

  Future<void> logout() async {
    try {
      await BackendService.logout();
    } catch (e) {
      _syncError = 'Signed out on this device. The server could not confirm session cleanup.';
    } finally {
      BackendService.token = null;
      StorageService.setSetting('backend_token', '');
      StorageService.setSetting('logged_in', '0');
      _authenticated = false;
      _clearCachedUserData();
      notifyListeners();
    }
  }

  Future<bool> requestPasswordResetCode(String email) async {
    try {
      await BackendService.requestPasswordResetCode(email.trim().toLowerCase());
      _syncError = null;
      return true;
    } catch (e) {
      _syncError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(
      String email, String code, String newPassword) async {
    if (newPassword.length < 6) {
      _syncError = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }
    try {
      await BackendService.resetPassword(
          email.trim().toLowerCase(), code.trim(), newPassword);
      _syncError = null;
      return true;
    } catch (e) {
      _syncError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  String get userDisplayName =>
      _userDisplayName.isNotEmpty ? _userDisplayName : currentAccount.name;

  String userSetting(String key) => _userSettings[key] ?? '';

  void setUserSetting(String key, String value) {
    _userSettings[key] = value;
    if (key == 'user_name') _userDisplayName = value;
    notifyListeners();
    unawaited(syncNow());
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppColors.darkMode = _themeMode == ThemeMode.dark;
    StorageService.setSetting(
        'theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
    unawaited(syncNow());
  }

  // ---------------- Backend synchronization ----------------
  Map<String, dynamic> _stateJson() => {
        'accounts': _accounts.map((e) => e.toJson()).toList(),
        'categories': _categories.map((e) => e.toJson()).toList(),
        'paymentMethods': _paymentMethods.map((e) => e.toJson()).toList(),
        'transactions': _transactions.map((e) => e.toJson()).toList(),
        'budgets': _budgets.map((e) => e.toJson()).toList(),
        'overallBudgets': _overallBudgets.map((e) => e.toJson()).toList(),
        'notes': _notes.map((e) => e.toJson()).toList(),
        'reminders': _reminders.map((e) => e.toJson()).toList(),
        'deletions': {
          for (final entry in _pendingDeletions.entries)
            entry.key: entry.value.toList(),
        },
        'settings': <String, dynamic>{
          ..._userSettings,
          'current_account_id': _currentAccountId,
          'theme_mode': _themeMode == ThemeMode.dark ? 'dark' : 'light',
          'recent_categories': _recentCategoryIds.join(','),
          'home_widgets': [
            showRecentTransactions,
            showPaymentMethod,
            showCategoryChart,
            showBudget,
            showTrend
          ].map((b) => b ? '1' : '0').join(','),
        },
      };

  void _queueDeletion(String table, String id) {
    _pendingDeletions.putIfAbsent(table, () => <String>{}).add(id);
  }

  Future<void> syncNow() async {
    await syncNowAndReport();
  }

  /// Returns true only after the complete current state has been accepted by
  /// the backend. A queue serializes full-state writes so concurrent edits do
  /// not overwrite one another with an older snapshot.
  Future<bool> syncNowAndReport() {
    final completer = Completer<bool>();
    _syncQueue = _syncQueue.then((_) async {
      final result = await _performSync();
      if (!completer.isCompleted) completer.complete(result);
    });
    return completer.future;
  }

  Future<bool> _performSync() async {
    if (BackendService.token == null || BackendService.token!.isEmpty) {
      _syncError = 'Not connected to a server account. Sign in while the API is available to synchronize data.';
      notifyListeners();
      return false;
    }
    _syncing = true;
    _syncError = null;
    try {
      final state = _stateJson();
      final sentDeletions = <String, Set<String>>{
        for (final entry in _pendingDeletions.entries)
          entry.key: Set<String>.from(entry.value),
      };
      final response = await BackendService.sync(state);
      if (response['success'] != true) {
        throw Exception(response['message']?.toString() ?? 'Synchronization failed.');
      }
      for (final entry in sentDeletions.entries) {
        _pendingDeletions[entry.key]?.removeAll(entry.value);
        if (_pendingDeletions[entry.key]?.isEmpty == true) {
          _pendingDeletions.remove(entry.key);
        }
      }
      _lastSyncAt = DateTime.now();
      StorageService.setSetting('last_sync_at', _lastSyncAt!.toIso8601String());
      StorageService.setSetting('last_sync_error', '');
      return true;
    } catch (e) {
      _syncError = e.toString().replaceFirst('Exception: ', '');
      StorageService.setSetting('last_sync_error', _syncError!);
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void _applyRemoteState(Map<String, dynamic> s) {
    List<Map<String, dynamic>> list(String key) => (s[key] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final accounts = list('accounts');
    _accounts = accounts.map(AccountModel.fromJson).toList();
    if (_accounts.isEmpty) {
      final fallback = AccountModel(id: 'default', name: 'Income Expense');
      _accounts = [fallback];
    }
    final remoteCategories = list('categories');
    _categories = remoteCategories.map(CategoryModel.fromJson).toList();
    if (_categories.isEmpty) {
      _categories = [...defaultIncomeCategories(), ...defaultExpenseCategories()];
    }
    final remotePaymentMethods = list('paymentMethods');
    _paymentMethods =
        remotePaymentMethods.map(PaymentMethodModel.fromJson).toList();
    if (_paymentMethods.isEmpty) {
      _paymentMethods = defaultPaymentMethods();
    }
    _transactions =
        list('transactions').map(TransactionModel.fromJson).toList();
    _budgets = list('budgets').map(BudgetModel.fromJson).toList();
    _overallBudgets =
        list('overallBudgets').map(OverallBudgetModel.fromJson).toList();
    _notes = list('notes').map(NoteModel.fromJson).toList();
    _reminders = list('reminders').map(ReminderModel.fromJson).toList();

    _receipts
      ..clear()
      ..addEntries(list('receipts')
          .map(ReceiptInfo.fromJson)
          .map((r) => MapEntry(r.id, r)));

    final rawSettings = s['settings'];
    final settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : <String, dynamic>{};
    _userSettings
      ..clear()
      ..addEntries(settings.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value.toString())));
    _userDisplayName =
        settings['user_name']?.toString() ?? _userDisplayName;
    final remoteAccount = settings['current_account_id']?.toString();
    if (remoteAccount != null &&
        _accounts.any((a) => a.id == remoteAccount)) {
      _currentAccountId = remoteAccount;
    } else if (_accounts.isNotEmpty) {
      _currentAccountId = _accounts.first.id;
    }
    final theme = settings['theme_mode']?.toString();
    if (theme == 'light' || theme == 'dark') {
      _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
      AppColors.darkMode = _themeMode == ThemeMode.dark;
    }
    final recent = settings['recent_categories']?.toString();
    _recentCategoryIds =
        recent == null || recent.isEmpty ? <String>[] : recent.split(',');
    if (settings['home_widgets'] != null) {
      final p = settings['home_widgets'].toString().split(',');
      if (p.length == 5) {
        showRecentTransactions = p[0] == '1';
        showPaymentMethod = p[1] == '1';
        showCategoryChart = p[2] == '1';
        showBudget = p[3] == '1';
        showTrend = p[4] == '1';
      }
    }

    StorageService.setSetting(
        'theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  // ---------------- Receipts (stored in the database) ----------------
  /// Metadata for a transaction's billPaths entry, or null for legacy
  /// device-path entries and receipts that no longer exist.
  ReceiptInfo? receiptForReference(String reference) {
    final id = ReceiptInfo.idFromReference(reference);
    return id == null ? null : _receipts[id];
  }

  /// reference -> file name, used by the Excel report.
  Map<String, String> get receiptLabels => {
        for (final r in _receipts.values) r.reference: r.fileName,
      };

  /// Uploads the file to the database and remembers its metadata. Throws with
  /// a readable message when the server rejects the file.
  Future<ReceiptInfo> uploadReceipt(Uint8List bytes, String fileName) async {
    final info = await BackendService.uploadReceipt(bytes, fileName);
    _receipts[info.id] = info;
    notifyListeners();
    return info;
  }

  /// Deletes an uploaded receipt that will not be (or is no longer) attached.
  Future<void> discardReceipt(String id) async {
    try {
      await BackendService.deleteReceipt(id);
    } catch (_) {
      // The server also removes unattached uploads automatically after a day.
    }
    _receipts.remove(id);
    notifyListeners();
  }

  // ---------------- Accounts (books) ----------------
  List<AccountModel> get accounts => _accounts;

  AccountModel get currentAccount =>
      _accounts.firstWhere((a) => a.id == _currentAccountId,
          orElse: () => _accounts.first);

  void switchAccount(String id) {
    _currentAccountId = id;
    notifyListeners();
    unawaited(syncNow());
  }

  void addAccount(String name) {
    final acc = AccountModel(id: _uuid.v4(), name: name);
    _accounts.add(acc);
    notifyListeners();
    unawaited(syncNow());
  }

  void renameAccount(String id, String name) {
    final acc = _accounts.firstWhere((a) => a.id == id);
    acc.name = name;
    notifyListeners();
    unawaited(syncNow());
  }

  // ---------------- Categories ----------------
  List<CategoryModel> get allCategories => _categories;

  List<CategoryModel> categoriesFor(CategoryKind kind) => _categories
      .where((c) => c.kind == kind || c.kind == CategoryKind.both)
      .toList();

  CategoryModel? categoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel addCategory({
    required String name,
    required IconData icon,
    required Color color,
    String? iconAsset,
    required CategoryKind kind,
  }) {
    final cat = CategoryModel(
      id: _uuid.v4(),
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.value,
      iconAsset: iconAsset,
      kind: kind,
      isCustom: true,
    );
    _categories.add(cat);
    notifyListeners();
    unawaited(syncNow());
    return cat;
  }

  /// Categories the user has actually used recently, most-recent first -
  /// shown as quick-pick chips above the full category grid.
  List<CategoryModel> recentCategoriesFor(CategoryKind kind, {int limit = 6}) {
    final result = <CategoryModel>[];
    for (final id in _recentCategoryIds) {
      final c = categoryById(id);
      if (c == null) continue;
      if (c.kind != kind && c.kind != CategoryKind.both) continue;
      if (result.any((e) => e.id == c.id)) continue;
      result.add(c);
      if (result.length >= limit) break;
    }
    return result;
  }

  void _touchRecentCategory(String? categoryId) {
    if (categoryId == null) return;
    _recentCategoryIds.remove(categoryId);
    _recentCategoryIds.insert(0, categoryId);
    if (_recentCategoryIds.length > 12) {
      _recentCategoryIds = _recentCategoryIds.sublist(0, 12);
    }
  }

  // ---------------- Payment methods ----------------
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;

  PaymentMethodModel? paymentMethodById(String? id) {
    if (id == null) return null;
    try {
      return _paymentMethods.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  PaymentMethodModel addPaymentMethod(String name) {
    final pm = PaymentMethodModel(id: _uuid.v4(), name: name, isCustom: true);
    _paymentMethods.add(pm);
    notifyListeners();
    unawaited(syncNow());
    return pm;
  }

  // ---------------- Transactions ----------------
  List<TransactionModel> get transactionsAllTime => _transactions
      .where((t) => t.accountId == _currentAccountId && !t.isDeleted)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> get transactionsEveryAccount => _transactions
      .where((t) => !t.isDeleted)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> get deletedTransactions => _transactions
      .where((t) => t.accountId == _currentAccountId && t.isDeleted)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> _filterByDateRange(
      List<TransactionModel> transactions, DateTime start, DateTime end) {
    final endExclusive = DateTime(end.year, end.month, end.day + 1);
    return transactions
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(endExclusive))
        .toList();
  }

  List<TransactionModel> transactionsInRange(DateTime start, DateTime end) =>
      _filterByDateRange(transactionsAllTime, start, end);

  List<TransactionModel> transactionsEveryAccountInRange(
          DateTime start, DateTime end) =>
      _filterByDateRange(transactionsEveryAccount, start, end);

  List<TransactionModel> get transactionsInSelectedRange =>
      transactionsInRange(rangeStart, rangeEnd);

  Future<bool> saveTransaction(TransactionModel transaction) async {
    final previous = List<TransactionModel>.from(_transactions);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index < 0) {
      _transactions.add(transaction);
    } else {
      _transactions[index] = transaction;
    }
    _touchRecentCategory(transaction.categoryId);
    notifyListeners();
    final saved = await syncNowAndReport();
    if (!saved) {
      _transactions = previous;
      notifyListeners();
    }
    return saved;
  }

  Future<bool> softDeleteTransaction(String id) async {
    final t = _transactions.firstWhere((e) => e.id == id);
    final wasDeleted = t.isDeleted;
    t.isDeleted = true;
    notifyListeners();
    final saved = await syncNowAndReport();
    if (!saved) {
      t.isDeleted = wasDeleted;
      notifyListeners();
    }
    return saved;
  }

  Future<bool> restoreTransaction(String id) async {
    final t = _transactions.firstWhere((e) => e.id == id);
    final wasDeleted = t.isDeleted;
    t.isDeleted = false;
    notifyListeners();
    final saved = await syncNowAndReport();
    if (!saved) {
      t.isDeleted = wasDeleted;
      notifyListeners();
    }
    return saved;
  }

  Future<bool> permanentlyDeleteTransaction(String id) async {
    final index = _transactions.indexWhere((e) => e.id == id);
    if (index < 0) return false;
    final removed = _transactions.removeAt(index);
    final wasPending = _pendingDeletions['transactions']?.contains(id) ?? false;
    _queueDeletion('transactions', id);
    notifyListeners();
    final saved = await syncNowAndReport();
    if (!saved) {
      _transactions.insert(
          index.clamp(0, _transactions.length).toInt(), removed);
      if (!wasPending) {
        _pendingDeletions['transactions']?.remove(id);
        if (_pendingDeletions['transactions']?.isEmpty == true) {
          _pendingDeletions.remove('transactions');
        }
      }
      notifyListeners();
    }
    return saved;
  }

  Map<String, dynamic> exportDataJson() => {
        'accounts': _accounts.map((e) => e.toJson()).toList(),
        'categories': _categories.map((e) => e.toJson()).toList(),
        'paymentMethods': _paymentMethods.map((e) => e.toJson()).toList(),
        'transactions': _transactions.map((e) => e.toJson()).toList(),
        'budgets': _budgets.map((e) => e.toJson()).toList(),
        'overallBudgets': _overallBudgets.map((e) => e.toJson()).toList(),
        'notes': _notes.map((e) => e.toJson()).toList(),
        'reminders': _reminders.map((e) => e.toJson()).toList(),
      };

  // ---------------- Aggregates ----------------
  double totalIncome(List<TransactionModel> list) => list
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double totalExpense(List<TransactionModel> list) => list
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double previousBalance(DateTime beforeDate) {
    final prior = transactionsAllTime.where((t) => t.date.isBefore(beforeDate));
    final inc = totalIncome(prior.toList());
    final exp = totalExpense(prior.toList());
    return inc - exp;
  }

  Map<String, double> expenseByCategory(List<TransactionModel> list) {
    final map = <String, double>{};
    for (final t in list.where((t) => t.type == TransactionType.expense)) {
      final name = categoryById(t.categoryId)?.name ?? 'Other';
      map[name] = (map[name] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> balanceByPaymentMethod() {
    final map = <String, double>{};
    for (final pm in _paymentMethods) {
      map[pm.name] = 0;
    }
    for (final t in transactionsAllTime) {
      final pmName = paymentMethodById(t.paymentMethodId)?.name;
      if (pmName == null) continue;
      if (t.type == TransactionType.income) {
        map[pmName] = (map[pmName] ?? 0) + t.amount;
      } else if (t.type == TransactionType.expense) {
        map[pmName] = (map[pmName] ?? 0) - t.amount;
      } else if (t.type == TransactionType.transfer) {
        map[pmName] = (map[pmName] ?? 0) - t.amount;
        final toName = paymentMethodById(t.toPaymentMethodId)?.name;
        if (toName != null) {
          map[toName] = (map[toName] ?? 0) + t.amount;
        }
      }
    }
    return map;
  }

  // ---------------- Budgets ----------------
  List<BudgetModel> budgetsFor(BudgetPeriod period, DateTime periodStart) =>
      _budgets
          .where((b) =>
              b.accountId == _currentAccountId &&
              b.period == period &&
              _samePeriod(b.periodStart, periodStart, period))
          .toList();

  bool _samePeriod(DateTime a, DateTime b, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        return a.year == b.year && a.month == b.month;
      case BudgetPeriod.yearly:
        return a.year == b.year;
      case BudgetPeriod.weekly:
        return a.year == b.year && _weekOfYear(a) == _weekOfYear(b);
    }
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final days = date.difference(firstDay).inDays;
    return ((days + firstDay.weekday) / 7).ceil();
  }

  BudgetModel setBudget({
    required String categoryId,
    required double amount,
    required BudgetPeriod period,
    required DateTime periodStart,
  }) {
    final existingIdx = _budgets.indexWhere((b) =>
        b.accountId == _currentAccountId &&
        b.categoryId == categoryId &&
        b.period == period &&
        _samePeriod(b.periodStart, periodStart, period));
    if (existingIdx != -1) {
      _budgets[existingIdx].amount = amount;
      notifyListeners();
    unawaited(syncNow());
      return _budgets[existingIdx];
    }
    final b = BudgetModel(
      id: _uuid.v4(),
      accountId: _currentAccountId,
      categoryId: categoryId,
      amount: amount,
      period: period,
      periodStart: periodStart,
    );
    _budgets.add(b);
    notifyListeners();
    unawaited(syncNow());
    return b;
  }

  void removeBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    _queueDeletion('budgets', id);
    notifyListeners();
    unawaited(syncNow());
  }

  void importBudgetsFromLastMonth(BudgetPeriod period, DateTime currentPeriodStart) {
    final lastPeriodStart = period == BudgetPeriod.monthly
        ? DateTime(currentPeriodStart.year, currentPeriodStart.month - 1, 1)
        : period == BudgetPeriod.yearly
            ? DateTime(currentPeriodStart.year - 1, 1, 1)
            : currentPeriodStart.subtract(Duration(days: 7));
    final last = budgetsFor(period, lastPeriodStart);
    for (final b in last) {
      setBudget(
        categoryId: b.categoryId,
        amount: b.amount,
        period: period,
        periodStart: currentPeriodStart,
      );
    }
  }

  OverallBudgetModel? overallBudgetFor(BudgetPeriod period, DateTime periodStart) {
    try {
      return _overallBudgets.firstWhere((o) =>
          o.accountId == _currentAccountId &&
          o.period == period &&
          _samePeriod(o.periodStart, periodStart, period));
    } catch (_) {
      return null;
    }
  }

  void setOverallBudget(BudgetPeriod period, DateTime periodStart, double amount) {
    final existing = overallBudgetFor(period, periodStart);
    if (existing != null) {
      existing.amount = amount;
    } else {
      final o = OverallBudgetModel(
        id: _uuid.v4(),
        accountId: _currentAccountId,
        amount: amount,
        period: period,
        periodStart: periodStart,
      );
      _overallBudgets.add(o);
    }
    notifyListeners();
    unawaited(syncNow());
  }

  // ---------------- Notes ----------------
  List<NoteModel> get notes =>
      _notes.where((n) => n.accountId == _currentAccountId).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  NoteModel addNote(String text, DateTime dateTime) {
    final n = NoteModel(
        id: _uuid.v4(),
        accountId: _currentAccountId,
        text: text,
        dateTime: dateTime);
    _notes.add(n);
    notifyListeners();
    unawaited(syncNow());
    return n;
  }

  void toggleNoteCompleted(String id) {
    final n = _notes.firstWhere((e) => e.id == id);
    n.completed = !n.completed;
    notifyListeners();
    unawaited(syncNow());
  }

  void deleteNote(String id) {
    _notes.removeWhere((e) => e.id == id);
    _queueDeletion('notes', id);
    notifyListeners();
    unawaited(syncNow());
  }

  // ---------------- Reminders ----------------
  List<ReminderModel> get reminders =>
      _reminders.where((r) => r.accountId == _currentAccountId).toList()
        ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

  List<ReminderModel> get remindersToday {
    final now = DateTime.now();
    return reminders
        .where((r) =>
            r.nextDate.year == now.year &&
            r.nextDate.month == now.month &&
            r.nextDate.day == now.day)
        .toList();
  }

  ReminderModel addReminder(ReminderModel r) {
    _reminders.add(r);
    notifyListeners();
    unawaited(syncNow());
    return r;
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((e) => e.id == id);
    _queueDeletion('reminders', id);
    notifyListeners();
    unawaited(syncNow());
  }

  /// Converts a reminder into a real transaction and advances its next date.
  Future<bool> applyReminder(String id) async {
    final r = _reminders.firstWhere((e) => e.id == id);
    final previousTransactions = List<TransactionModel>.from(_transactions);
    final previousReminders = List<ReminderModel>.from(_reminders);
    final previousNextDate = r.nextDate;
    final reminderDeletionWasPending =
        _pendingDeletions['reminders']?.contains(id) ?? false;
    _transactions.add(TransactionModel(
      id: _uuid.v4(),
      accountId: _currentAccountId,
      type: r.type,
      amount: r.amount,
      categoryId: r.categoryId,
      paymentMethodId: r.paymentMethodId,
      notes: r.notes,
      date: r.nextDate,
    ));
    switch (r.recurrence) {
      case RecurrenceType.once:
        _reminders.removeWhere((item) => item.id == id);
        _queueDeletion('reminders', id);
        break;
      case RecurrenceType.daily:
        r.nextDate = r.nextDate.add(Duration(days: 1));
        break;
      case RecurrenceType.weekly:
        r.nextDate = r.nextDate.add(Duration(days: 7));
        break;
      case RecurrenceType.monthly:
        r.nextDate =
            DateTime(r.nextDate.year, r.nextDate.month + 1, r.nextDate.day);
        break;
      case RecurrenceType.yearly:
        r.nextDate =
            DateTime(r.nextDate.year + 1, r.nextDate.month, r.nextDate.day);
        break;
    }
    _touchRecentCategory(r.categoryId);
    notifyListeners();
    final saved = await syncNowAndReport();
    if (!saved) {
      _transactions = previousTransactions;
      _reminders = previousReminders;
      r.nextDate = previousNextDate;
      if (!reminderDeletionWasPending) {
        _pendingDeletions['reminders']?.remove(id);
        if (_pendingDeletions['reminders']?.isEmpty == true) {
          _pendingDeletions.remove('reminders');
        }
      }
      notifyListeners();
    }
    return saved;
  }

  // ---------------- Date range helpers ----------------
  void setRange(DateTime start, DateTime end, DateRangeMode mode) {
    rangeStart = start;
    rangeEnd = end;
    rangeMode = mode;
    notifyListeners();
    unawaited(syncNow());
  }

  void shiftRange(int direction) {
    switch (rangeMode) {
      case DateRangeMode.monthly:
        final newMonth = DateTime(
            rangeStart.year, rangeStart.month + direction, 1);
        rangeStart = newMonth;
        rangeEnd = DateTime(newMonth.year, newMonth.month + 1, 0, 23, 59, 59);
        break;
      case DateRangeMode.weekly:
        rangeStart = rangeStart.add(Duration(days: 7 * direction));
        rangeEnd = rangeEnd.add(Duration(days: 7 * direction));
        break;
      case DateRangeMode.yearly:
        rangeStart = DateTime(rangeStart.year + direction, 1, 1);
        rangeEnd = DateTime(rangeStart.year, 12, 31, 23, 59, 59);
        break;
      case DateRangeMode.daily:
        rangeStart = DateTime(rangeStart.year, rangeStart.month,
            rangeStart.day + direction);
        rangeEnd = DateTime(rangeStart.year, rangeStart.month,
            rangeStart.day, 23, 59, 59);
        break;
      case DateRangeMode.custom:
      case DateRangeMode.all:
        break;
    }
    notifyListeners();
    unawaited(syncNow());
  }
}
