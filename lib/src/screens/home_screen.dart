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
    for (final a in apartments) {
      for (var offset = -1; offset <= 12; offset++) {
        final m = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
        final payment = await AppDatabase.instance.getPayment(a.id!, m);
        final key = _key(a.id!, m);
        paid[key] = payment?['paid'] == 1;
        amounts[key] = payment?['amount'] as int? ?? a.rentFor(m);
      }
    }
    if (mounted) setState(() { _apartments = apartments; _paid = paid; _amounts = amounts; _loading = false; });
  }

  Future<void> _toggle(Apartment a, DateTime month) async {
    final key = _key(a.id!, month);
    final current = _paid[key] ?? false;
    await AppDatabase.instance.setPayment(a.id!, month, _amounts[key] ?? a.rentFor(month), !current);
    await _load();
  }

  Future<void> _editAmount(Apartment a, DateTime month) async {
    final controller = TextEditingController(text: '${_amounts[_key(a.id!, month)] ?? a.rentFor(month)}');
    final result = await showDialog<int>(context: context, builder: (context) => AlertDialog(
      title: Text('${a.name} · ${monthLabel(month)}'),
      content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kira tutarı (TL)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: () { final n = int.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '')); if (n != null && n > 0) Navigator.pop(context, n); }, child: const Text('Kaydet')),
      ],
    ));
    if (result != null) {
      final effective = a.hasScheduledIncrease ? DateTime(a.increaseYear!, a.increaseMonth!) : null;
      if (effective != null && !DateTime(month.year, month.month).isBefore(effective) && a.increaseRent == null) {
        final updated = Apartment(
          id: a.id, name: a.name, tenant: a.tenant, rent: a.rent, paymentDay: a.paymentDay,
          increaseRent: result, increaseMonth: a.increaseMonth, increaseYear: a.increaseYear,
        );
        await AppDatabase.instance.saveApartment(updated.toMap());
      }
      await AppDatabase.instance.setPayment(a.id!, month, result, _paid[_key(a.id!, month)] ?? false);
      await _load();
    }
  }

  Future<void> _openForm([Apartment? a]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ApartmentForm(apartment: a)));
    await _load();
  }

  List<DateTime> get _months => List.generate(14, (i) => DateTime(_selectedMonth.year, _selectedMonth.month + i - 1));

  @override
  Widget build(BuildContext context) {
    final current = _selectedMonth;
    var expected = 0, collected = 0;
    for (final a in _apartments) {
      final amount = _amounts[_key(a.id!, current)] ?? a.rentFor(current);
      expected += amount;
      if (_paid[_key(a.id!, current)] == true) collected += amount;
    }
    final remaining = expected - collected;
    return Scaffold(
      appBar: AppBar(title: const Text('Kira Hoçet'), actions: [
        IconButton(tooltip: 'Önceki ay', onPressed: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)); _load(); }, icon: const Icon(Icons.chevron_left)),
        Center(child: Text(monthLabel(_selectedMonth), style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(tooltip: 'Sonraki ay', onPressed: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)); _load(); }, icon: const Icon(Icons.chevron_right)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 18), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bu ayın kira durumu', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SummaryValue(label: 'Toplanan', value: money(collected), color: Colors.green.shade700)),
              Expanded(child: _SummaryValue(label: 'Kalan', value: money(remaining), color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: expected == 0 ? 0 : collected / expected, minHeight: 12, backgroundColor: Colors.grey.shade300, color: AppTheme.green)),
            const SizedBox(height: 6),
            Text('Beklenen toplam: ${money(expected)}', style: Theme.of(context).textTheme.bodySmall),
          ]))),
          const SizedBox(height: 14),
          const Text('Aylık kira tablosu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (_apartments.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Henüz daire eklenmedi. Başlamak için “Daire ekle”ye dokun.')))
          else
            Card(child: SizedBox(
              height: 72 + _apartments.length * widget.rowHeight,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 126, child: Column(children: [
                  _headerCell('Daire / Kiracı', 56, true),
                  ..._apartments.map((a) => InkWell(
                    onTap: () => _openForm(a),
                    child: Container(height: widget.rowHeight, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(a.tenant, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('Her ayın ${a.paymentDay}. günü', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ]),
                    ),
                  )),
                ])),
                Expanded(child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _months.map((m) {
                    final isCurrent = m.year == DateTime.now().year && m.month == DateTime.now().month;
                    return SizedBox(width: widget.monthWidth, child: Column(children: [
                      _headerCell(monthLabel(m), 56, isCurrent),
                      ..._apartments.map((a) {
                        final key = _key(a.id!, m);
                        final paid = _paid[key] ?? false;
                        final amount = _amounts[key] ?? a.rentFor(m);
                        final increaseStart = a.hasScheduledIncrease ? DateTime(a.increaseYear!, a.increaseMonth!) : null;
                        final isAfterUnpricedIncrease = increaseStart != null && !DateTime(m.year, m.month).isBefore(increaseStart) && a.increaseRent == null;
                        final isIncreaseApproaching = increaseStart != null && DateTime(m.year, m.month).isBefore(increaseStart) && DateTime(m.year, m.month + 1).year == increaseStart.year && DateTime(m.year, m.month + 1).month == increaseStart.month;
                        final hasNoNewAmount = isAfterUnpricedIncrease;
                        final background = paid ? AppTheme.paleGreen : (hasNoNewAmount || isIncreaseApproaching) ? AppTheme.amber : isCurrent ? const Color(0xFFEAF2FF) : Colors.white;
                        return InkWell(
                          onTap: () => _toggle(a, m),
                          onLongPress: () => _editAmount(a, m),
                          child: Container(height: widget.rowHeight, width: widget.monthWidth, margin: const EdgeInsets.all(2), padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9), border: Border.all(color: isCurrent ? Colors.blue.shade200 : Colors.transparent)),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(hasNoNewAmount ? 'TUTAR GİR' : money(amount), maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: paid ? Colors.green.shade800 : hasNoNewAmount ? Colors.orange.shade900 : Colors.black87)),
                              const SizedBox(height: 4),
                              if (paid) const Text('ALINDI', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))
                              else if (hasNoNewAmount) Text('TUTAR GİR', style: TextStyle(fontSize: 9, color: Colors.orange.shade900, fontWeight: FontWeight.bold))
                              else if (isIncreaseApproaching) Text('ZAM YAKLAŞIYOR', style: TextStyle(fontSize: 8, color: Colors.orange.shade900, fontWeight: FontWeight.bold))
                              else Text('Dokun: alındı', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                            ]),
                          ),
                        );
                      }),
                    ]));
                  }).toList()),
                )),
              ]),
            )),
          const SizedBox(height: 8),
          Text('İpucu: Kira hücresine dokunarak ödendi/geri al; tutarı düzenlemek için basılı tut.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Daire ekle'))),
        ]),
      ),
    );
  }

  Widget _headerCell(String text, double height, bool active) => Container(
    height: height, alignment: Alignment.center, margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(color: active ? const Color(0xFFDCEBFF) : const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8)),
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.blue.shade800 : Colors.black87)),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
  ]);
}
