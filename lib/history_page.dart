import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'app_colors.dart';
import 'transaction_model.dart';
import 'history_provider.dart';
import 'history_widgets.dart';
import 'transaction_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late final HistoryProvider _provider;
  final _searchController = TextEditingController();
  bool _showSearch = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _provider = HistoryProvider()..init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _provider.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) => Scaffold(
        backgroundColor: BCAColors.lightGray,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) =>
              [_buildAppBar(innerBoxIsScrolled)],
          body: _buildBody(),
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: innerBoxIsScrolled ? 2 : 0,
      backgroundColor: BCAColors.primaryBlue,
      title: _showSearch
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Cari transaksi...',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
              ),
              onChanged: _provider.search,
            )
          : const Text(
              'Riwayat Transaksi',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
      leading: _showSearch
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() => _showSearch = false);
                _searchController.clear();
                _provider.search('');
              },
            )
          : IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (!_showSearch) ...[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _showSearch = true),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
              if (_provider.hasActiveFilter)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _downloadPDF,
          ),
        ],
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Riwayat'),
          Tab(text: 'Ringkasan'),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildHistoryTab(),
        _buildSummaryTab(),
      ],
    );
  }

  // ── History Tab ───────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildCategoryFilter(),
        if (_provider.hasActiveFilter) _buildActiveFilters(),
        Expanded(child: _buildTransactionList()),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CategoryFilterChip(
              category: null,
              selected: _provider.selectedCategory == null,
              onTap: () => _provider.setCategory(null),
            ),
            const SizedBox(width: 8),
            ...TransactionCategory.values.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryFilterChip(
                    category: cat,
                    selected: _provider.selectedCategory == cat,
                    onTap: () => _provider.setCategory(
                        _provider.selectedCategory == cat ? null : cat),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    if (_provider.incomeFilter != null) {
      chips.add(_activeChip(
        _provider.incomeFilter! ? 'Pemasukan' : 'Pengeluaran',
        () => _provider.setIncomeFilter(null),
      ));
    }
    if (_provider.selectedStatus != null) {
      chips.add(_activeChip(
        _provider.selectedStatus!.label,
        () => _provider.setStatus(null),
      ));
    }
    if (_provider.dateRange != null) {
      final r = _provider.dateRange!;
      chips.add(_activeChip(
        '${DateFormat('d MMM', 'id').format(r.start)} – '
        '${DateFormat('d MMM', 'id').format(r.end)}',
        () => _provider.setDateRange(null),
      ));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          ...chips,
          TextButton(
            onPressed: _provider.clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Hapus semua',
                style: TextStyle(
                    color: BCAColors.expenseRed, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: BCAColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: BCAColors.primaryBlue,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: BCAColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final grouped = _provider.groupedTransactions;

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: BCAColors.secondaryText.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Tidak ada transaksi',
                style: TextStyle(
                    color: BCAColors.secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Coba ubah filter atau pencarian',
                style: TextStyle(
                    color: BCAColors.secondaryText, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BCAColors.secondaryText,
                      letterSpacing: 0.3)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: entry.value.asMap().entries.map((e) {
                  final isLast = e.key == entry.value.length - 1;
                  return Column(
                    children: [
                      TransactionTile(
                        tx: e.value,
                        onTap: () => _openDetail(e.value),
                      ),
                      if (!isLast)
                        const Divider(
                            height: 1,
                            indent: 72,
                            color: BCAColors.divider),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Summary Tab ───────────────────────────────────────────────

  Widget _buildSummaryTab() {
    final summary = _provider.summary;
    if (summary == null) {
      return const Center(
          child: CircularProgressIndicator(color: BCAColors.primaryBlue));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        MonthlySummaryCard(
          summary: summary,
          onPrevMonth: () => _provider.changeMonth(DateTime(
            _provider.selectedMonth.year,
            _provider.selectedMonth.month - 1,
          )),
          onNextMonth: () => _provider.changeMonth(DateTime(
            _provider.selectedMonth.year,
            _provider.selectedMonth.month + 1,
          )),
        ),
        _buildCashFlowSection(summary),
        _buildCategoryBreakdown(),
      ],
    );
  }

  Widget _buildCashFlowSection(MonthlySummary summary) {
    final max =
        [summary.totalIncome, summary.totalExpense].reduce((a, b) => a > b ? a : b);
    final incW = max > 0 ? summary.totalIncome / max : 0.0;
    final expW = max > 0 ? summary.totalExpense / max : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cash Flow',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: BCAColors.textDark)),
          const SizedBox(height: 16),
          _barRow('Pemasukan', summary.totalIncome, incW,
              BCAColors.incomeGreen),
          const SizedBox(height: 10),
          _barRow('Pengeluaran', summary.totalExpense, expW,
              BCAColors.expenseRed),
        ],
      ),
    );
  }

  Widget _barRow(
      String label, double amount, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: BCAColors.secondaryText)),
            Text(formatCurrency(amount),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: BCAColors.lightGray,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final map = <TransactionCategory, double>{};
    for (final tx in _provider.transactions) {
      if (!tx.isIncome && tx.status == TransactionStatus.berhasil) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox();

    final total = sorted.fold(0.0, (s, e) => s + e.value);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengeluaran per Kategori',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: BCAColors.textDark)),
          const SizedBox(height: 16),
          ...sorted.map((entry) {
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: entry.key.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(entry.key.icon,
                            color: entry.key.color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.key.label,
                            style: const TextStyle(
                                fontSize: 13,
                                color: BCAColors.textDark,
                                fontWeight: FontWeight.w500)),
                      ),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 12,
                              color: entry.key.color,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(formatCurrency(entry.value),
                          style: const TextStyle(
                              fontSize: 13,
                              color: BCAColors.expenseRed,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: BCAColors.lightGray,
                      valueColor:
                          AlwaysStoppedAnimation(entry.key.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────

  void _openDetail(TransactionModel tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TransactionDetailPage(transaction: tx)),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FilterBottomSheet(provider: _provider),
      ),
    );
  }

  Future<void> _downloadPDF() async {
    final txList = _provider.transactions;
    if (txList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak ada data untuk diekspor')));
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) => [
        pw.Header(
          level: 0,
          child: pw.Text('Laporan Transaksi MyBCA',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Dicetak: ${DateFormat('d MMMM yyyy HH:mm', 'id').format(DateTime.now())}'),
        pw.SizedBox(height: 16),
        pw.Table.fromTextArray(
          headers: [
            'Tanggal', 'Keterangan', 'Kategori',
            'Jenis', 'Jumlah', 'Status'
          ],
          data: txList
              .map((tx) => [
                    DateFormat('d MMM yyyy', 'id').format(tx.date),
                    tx.title,
                    tx.category.label,
                    tx.isIncome ? 'Masuk' : 'Keluar',
                    formatCurrency(tx.amount),
                    tx.status.label,
                  ])
              .toList(),
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellPadding: const pw.EdgeInsets.all(4),
        ),
      ],
    ));

    final bytes = await pdf.save();
    await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'laporan-mybca.pdf');
  }
}
