import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_colors.dart';
import 'transaction_model.dart';
import 'history_provider.dart';

// ── Formatter ────────────────────────────────────────────────

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatCurrency(double amount) => _idr.format(amount);

// ── Category Filter Chip ──────────────────────────────────────

class CategoryFilterChip extends StatelessWidget {
  final TransactionCategory? category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = category?.label ?? 'Semua';
    final color = category?.color ?? BCAColors.primaryBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : BCAColors.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Icon(
                category!.icon,
                size: 14,
                color: selected ? Colors.white : BCAColors.secondaryText,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : BCAColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final TransactionStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;

  const TransactionTile({super.key, required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tx.category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tx.category.icon, color: tx.category.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BCAColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        tx.category.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: BCAColors.secondaryText,
                        ),
                      ),
                      if (tx.status != TransactionStatus.berhasil) ...[
                        const SizedBox(width: 6),
                        StatusBadge(status: tx.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount & time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tx.isIncome
                        ? BCAColors.incomeGreen
                        : BCAColors.expenseRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(tx.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: BCAColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Monthly Summary Card ──────────────────────────────────────

class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const MonthlySummaryCard({
    super.key,
    required this.summary,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.netCashFlow >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BCAColors.primaryBlue, BCAColors.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BCAColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: onPrevMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                summary.monthLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: onNextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Income / Expense row
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Pemasukan',
                  amount: summary.totalIncome,
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF4FC98A),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _SummaryItem(
                  label: 'Pengeluaran',
                  amount: summary.totalExpense,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFFF7B7B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Net cash flow
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Cash Flow',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '${isPositive ? '+' : ''}${formatCurrency(summary.netCashFlow)}',
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF4FC98A)
                        : const Color(0xFFFF7B7B),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────

class FilterBottomSheet extends StatefulWidget {
  final HistoryProvider provider;
  const FilterBottomSheet({super.key, required this.provider});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  DateTimeRange? _range;
  TransactionCategory? _cat;
  TransactionStatus? _status;
  bool? _incomeFilter;

  @override
  void initState() {
    super.initState();
    _range        = widget.provider.dateRange;
    _cat          = widget.provider.selectedCategory;
    _status       = widget.provider.selectedStatus;
    _incomeFilter = widget.provider.incomeFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BCAColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transaksi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BCAColors.textDark),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _range        = null;
                  _cat          = null;
                  _status       = null;
                  _incomeFilter = null;
                }),
                child: const Text('Reset',
                    style: TextStyle(color: BCAColors.secondaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date range
          _sectionLabel('Periode'),
          OutlinedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _range,
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: BCAColors.primaryBlue),
                  ),
                  child: child!,
                ),
              );
              if (range != null) setState(() => _range = range);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(_range == null
                ? 'Pilih tanggal'
                : '${DateFormat('d MMM', 'id').format(_range!.start)} – '
                    '${DateFormat('d MMM yyyy', 'id').format(_range!.end)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BCAColors.primaryBlue,
              side: const BorderSide(color: BCAColors.primaryBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          _sectionLabel('Kategori'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Semua', _cat == null, () => setState(() => _cat = null)),
              ...TransactionCategory.values.map((c) => _chip(
                    c.label,
                    _cat == c,
                    () => setState(() => _cat = c),
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Status
          _sectionLabel('Status'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Semua', _status == null,
                  () => setState(() => _status = null)),
              ...TransactionStatus.values.map((s) => _chip(
                    s.label,
                    _status == s,
                    () => setState(() => _status = s),
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Jenis
          _sectionLabel('Jenis'),
          Wrap(
            spacing: 8,
            children: [
              _chip('Semua', _incomeFilter == null,
                  () => setState(() => _incomeFilter = null)),
              _chip('Pemasukan', _incomeFilter == true,
                  () => setState(() => _incomeFilter = true)),
              _chip('Pengeluaran', _incomeFilter == false,
                  () => setState(() => _incomeFilter = false)),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.provider.setCategory(_cat);
                widget.provider.setStatus(_status);
                widget.provider.setDateRange(_range);
                widget.provider.setIncomeFilter(_incomeFilter);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BCAColors.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Terapkan Filter',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BCAColors.textDark)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? BCAColors.primaryBlue : BCAColors.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : BCAColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
