import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/apartment.dart';
import '../theme/app_theme.dart';
import '../widgets/money.dart';
import 'apartment_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.fontScale, required this.rowHeight, required this.monthWidth});
  final double fontScale;
  final double rowHeight;
  final double monthWidth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;
  List<Apartment> _apartments = [];
  Map<String, bool> _paid = {};
  Map<String, int> _amounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _load();
  }

  String _key(int id, DateTime month) => '$id-${month.year}-${month.month}';

  Future<void> _load() async {
    final rows = await AppDatabase.instance.getApartments();
    final apartments = rows.map(Apartment.fromMap).toList();
    final paid = <String, bool>{};
    final amounts = <String, int>{};
    for (final apartment in apartments) {
      for (var offset = -1; offset <= 12; offset++) {
        final month = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
        final payment = await AppDatabase.instance.getPayment(apartment.id!, month);
        final key = _key(apartment.id!, month);
        paid[key] = payment?['paid'] == 1;
        amounts[key] = payment?['amount'] as int? ?? apartment.rentFor(month);
      }
    }
    if (!mounted) return;
    setState(() {
      _apartments = apartments;
      _paid = paid;
      _amounts = amounts;
      _loading = false;
    });
  }

  Future<void> _toggle(Apartment apartment, DateTime month) async {
    final key = _key(apartment.id!, month);
    final alreadyPaid = _paid[key] ?? false;
    final increaseStart = apartment.hasScheduledIncrease
        ? DateTime(apartment.increaseYear!, apartment.increaseMonth!)
        : null;
    final needsIncreaseAmount = increaseStart != null &&
        !DateTime(month.year, month.month).isBefore(increaseStart) &&
        apartment.increaseRent == null;

    if (!alreadyPaid && needsIncreaseAmount) {
      await _editAmount(apartment, month);
      return;
    }

    final question = alreadyPaid
        ? '${apartment.name}, ${monthLabel(month)} kira tahsilatını geri almak istiyor musunuz?'
        : '${apartment.name}, ${monthLabel(month)} kira bedeli alındı mı?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(alreadyPaid ? 'Tahsilatı geri al' : 'Kira tahsilatı'),
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(alreadyPaid ? 'Evet, geri al' : 'Evet, alındı'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AppDatabase.instance.setPayment(
      apartment.id!,
      month,
      _amounts[key] ?? apartment.rentFor(month),
      !alreadyPaid,
    );
    await _load();
  }

  Future<void> _editAmount(Apartment apartment, DateTime month) async {
    final key = _key(apartment.id!, month);
    final controller = TextEditingController(
      text: '${_amounts[key] ?? apartment.rentFor(month)}',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${apartment.name} · ${monthLabel(month)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Kira tutarı (TL)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(
                controller.text.replaceAll('.', '').replaceAll(',', ''),
              );
              if (value != null && value > 0) Navigator.pop(dialogContext, value);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    final increaseStart = apartment.hasScheduledIncrease
        ? DateTime(apartment.increaseYear!, apartment.increaseMonth!)
        : null;
    if (increaseStart != null &&
        !DateTime(month.year, month.month).isBefore(increaseStart) &&
        apartment.increaseRent == null) {
      final updated = Apartment(
        id: apartment.id,
        name: apartment.name,
        tenant: apartment.tenant,
        rent: apartment.rent,
        paymentDay: apartment.paymentDay,
        increaseRent: result,
        increaseMonth: apartment.increaseMonth,
        increaseYear: apartment.increaseYear,
      );
      await AppDatabase.instance.saveApartment(updated.toMap());
    }

    await AppDatabase.instance.setPayment(
      apartment.id!,
      month,
      result,
      _paid[key] ?? false,
    );
    await _load();
  }

  Future<void> _openForm([Apartment? apartment]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ApartmentForm(apartment: apartment)),
    );
    await _load();
  }

  void _changeMonth(int difference) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + difference);
      _loading = true;
    });
    _load();
  }

  List<DateTime> get _months => List.generate(
        14,
        (index) => DateTime(_selectedMonth.year, _selectedMonth.month + index - 1),
      );

  @override
  Widget build(BuildContext context) {
    var expected = 0;
    var collected = 0;
    for (final apartment in _apartments) {
      final amount = _amounts[_key(apartment.id!, _selectedMonth)] ??
          apartment.rentFor(_selectedMonth);
      expected += amount;
      if (_paid[_key(apartment.id!, _selectedMonth)] == true) collected += amount;
    }
    final remaining = expected - collected;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                children: [
                  _RentSummaryBar(
                    collected: collected,
                    remaining: remaining,
                    expected: expected,
                  ),
                  const SizedBox(height: 8),
                  if (_apartments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Henüz daire eklenmedi. Başlamak için “Daire ekle”ye dokun.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: 56 + _apartments.length * widget.rowHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 126,
                              child: Column(
                                children: [
                                  _headerCell('Daire / Kiracı', 52, true),
                                  ..._apartments.map(
                                    (apartment) => InkWell(
                                      onTap: () => _openForm(apartment),
                                      child: Container(
                                        height: widget.rowHeight,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(apartment.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(apartment.tenant, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            Text('Her ayın ${apartment.paymentDay}. günü',
                                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _months.map((month) {
                                    final isCurrent = month.year == DateTime.now().year &&
                                        month.month == DateTime.now().month;
                                    return SizedBox(
                                      width: widget.monthWidth,
                                      child: Column(
                                        children: [
                                          _headerCell(monthLabel(month), 52, isCurrent),
                                          ..._apartments.map((apartment) {
                                            final key = _key(apartment.id!, month);
                                            final paid = _paid[key] ?? false;
                                            final amount = _amounts[key] ?? apartment.rentFor(month);
                                            final increaseStart = apartment.hasScheduledIncrease
                                                ? DateTime(apartment.increaseYear!, apartment.increaseMonth!)
                                                : null;
                                            final afterUnpricedIncrease = increaseStart != null &&
                                                !DateTime(month.year, month.month).isBefore(increaseStart) &&
                                                apartment.increaseRent == null;
                                            final increaseMonth = increaseStart != null &&
                                                month.year == increaseStart.year &&
                                                month.month == increaseStart.month;
                                            final increaseApproaching = increaseStart != null &&
                                                DateTime(month.year, month.month).isBefore(increaseStart) &&
                                                DateTime(month.year, month.month + 1).year == increaseStart.year &&
                                                DateTime(month.year, month.month + 1).month == increaseStart.month;

                                            final background = paid
                                                ? AppTheme.paleGreen
                                                : (afterUnpricedIncrease || increaseApproaching)
                                                    ? AppTheme.amber
                                                    : isCurrent
                                                        ? const Color(0xFFEAF2FF)
                                                        : Colors.white;

                                            return InkWell(
                                              onTap: () => _toggle(apartment, month),
                                              onLongPress: () => _editAmount(apartment, month),
                                              child: Container(
                                                height: widget.rowHeight,
                                                width: widget.monthWidth,
                                                margin: const EdgeInsets.all(2),
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: background,
                                                  borderRadius: BorderRadius.circular(9),
                                                  border: Border.all(
                                                    color: isCurrent ? Colors.blue.shade200 : Colors.transparent,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    if (afterUnpricedIncrease)
                                                      Text(
                                                        'ZAMLI KİRA',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.orange.shade900,
                                                        ),
                                                      )
                                                    else
                                                      Text(
                                                        money(amount),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          color: paid ? Colors.green.shade800 : Colors.black87,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 3),
                                                    if (paid)
                                                      const Text('ALINDI', style: TextStyle(
                                                        fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold,
                                                      ))
                                                    else if (afterUnpricedIncrease)
                                                      Text('Tutar gir', style: TextStyle(
                                                        fontSize: 10, color: Colors.orange.shade900, fontWeight: FontWeight.w600,
                                                      ))
                                                    else if (increaseApproaching)
                                                      Text('ZAM YAKLAŞIYOR', style: TextStyle(
                                                        fontSize: 8, color: Colors.orange.shade900, fontWeight: FontWeight.bold,
                                                      ))
                                                    else if (increaseMonth)
                                                      const Text('ZAMLI KİRA', style: TextStyle(
                                                        fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold,
                                                      )),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Önceki ay',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(monthLabel(_selectedMonth),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        tooltip: 'Sonraki ay',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Daire ekle'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daire bilgilerini düzenlemek için daire adına, kira tutarını değiştirmek için hücreye basılı tut.',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _headerCell(String text, double height, bool active) {
    return Container(
      height: height,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCEBFF) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: active ? Colors.blue.shade800 : Colors.black87,
        ),
      ),
    );
  }
}

class _RentSummaryBar extends StatelessWidget {
  const _RentSummaryBar({
    required this.collected,
    required this.remaining,
    required this.expected,
  });

  final int collected;
  final int remaining;
  final int expected;

  @override
  Widget build(BuildContext context) {
    final collectedFlex = expected <= 0 ? 0 : (collected / expected * 1000).round().clamp(0, 1000).toInt();
    final remainingFlex = expected <= 0 ? 1 : (1000 - collectedFlex).clamp(0, 1000).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (collectedFlex > 0)
              Expanded(
                flex: collectedFlex,
                child: Container(
                  color: AppTheme.green,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${money(collected)} Toplanan',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF145C32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            if (remainingFlex > 0)
              Expanded(
                flex: remainingFlex,
                child: Container(
                  color: const Color(0xFFB8BEC5),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${money(remaining)} Kalan',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF303840),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
