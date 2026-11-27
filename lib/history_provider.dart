import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'transaction_model.dart';
import 'history_service.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryService _service = HistoryService();
  StreamSubscription<List<TransactionModel>>? _sub;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filtered = [];
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  TransactionCategory? _selectedCategory;
  TransactionStatus? _selectedStatus;
  bool? _incomeFilter;
  DateTime _selectedMonth = DateTime.now();
  MonthlySummary? _summary;

  List<TransactionModel> get transactions => _filtered;
  String get searchQuery => _searchQuery;
  DateTimeRange? get dateRange => _dateRange;
  TransactionCategory? get selectedCategory => _selectedCategory;
  TransactionStatus? get selectedStatus => _selectedStatus;
  bool? get incomeFilter => _incomeFilter;
  MonthlySummary? get summary => _summary;
  DateTime get selectedMonth => _selectedMonth;

  bool get hasActiveFilter =>
      _dateRange != null ||
      _selectedCategory != null ||
      _selectedStatus != null ||
      _incomeFilter != null;

  Map<String, List<TransactionModel>> get groupedTransactions {
    final map = <String, List<TransactionModel>>{};
    for (final tx in _filtered) {
      final key = DateFormat('d MMMM yyyy', 'id').format(tx.date);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  void init() {
    _sub?.cancel();
    _sub = _service.streamTransactions().listen(
      (list) {
        _transactions = list;
        _applyFilters();
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('History stream error: $e');
      },
    );
    _loadSummary();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _applyFilters() {
    _filtered = _transactions.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!tx.title.toLowerCase().contains(q) &&
            !(tx.subtitle?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }

      if (_selectedCategory != null && tx.category != _selectedCategory) {
        return false;
      }

      if (_selectedStatus != null && tx.status != _selectedStatus) {
        return false;
      }

      if (_incomeFilter != null && tx.isIncome != _incomeFilter) {
        return false;
      }

      if (_dateRange != null) {
        if (tx.date.isBefore(_dateRange!.start) ||
            tx.date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void search(String q) {
    _searchQuery = q;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(TransactionCategory? cat) {
    _selectedCategory = cat;
    _applyFilters();
    notifyListeners();
  }

  void setStatus(TransactionStatus? st) {
    _selectedStatus = st;
    _applyFilters();
    notifyListeners();
  }

  void setIncomeFilter(bool? val) {
    _incomeFilter = val;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _dateRange = null;
    _selectedCategory = null;
    _selectedStatus = null;
    _incomeFilter = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void changeMonth(DateTime month) {
    _selectedMonth = month;
    _loadSummary();
    notifyListeners();
  }

  Future<void> _loadSummary() async {
    _summary = await _service.getMonthlySummary(_selectedMonth);
    notifyListeners();
  }
}
