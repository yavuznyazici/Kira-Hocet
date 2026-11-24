import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/app_database.dart';
import '../models/apartment.dart';
import '../widgets/money.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Apartment> _apartments = [];
  int? _selectedId;
  double _percent = 25;

  late final TextEditingController _rentController;
  int _currentRent = 0;

  @override
  void initState() {
    super.initState();
    _rentController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await AppDatabase.instance.getApartments();
    if (!mounted) return;

    final apartments = rows.map(Apartment.fromMap).toList();
    final selectedId = _selectedId ??
        (apartments.isEmpty ? null : apartments.first.id);
    final selected = apartments.where((a) => a.id == selectedId).firstOrNull;

    setState(() {
      _apartments = apartments;
      _selectedId = selectedId;
      _currentRent = selected?.rent ?? 0;
      _rentController.text = selected == null ? '' : selected.rent.toString();
    });
  }

  void _selectApartment(int? id) {
    final apartment = _apartments.where((a) => a.id == id).firstOrNull;

    setState(() {
      _selectedId = id;
      _currentRent = apartment?.rent ?? 0;
      _rentController.text =
          apartment == null ? '' : apartment.rent.toString();
    });
  }

  void _updateRent(String value) {
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    setState(() {
      _currentRent = parsed ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        _apartments.where((a) => a.id == _selectedId).firstOrNull;
    final newRent = selected == null
        ? 0
        : (_currentRent * (1 + _percent / 100)).round();

    final total = _apartments.fold<int>(0, (sum, a) => sum + a.rent);
    final average =
        _apartments.isEmpty ? 0 : (total / _apartments.length).round();
    final highest = _apartments.isEmpty
        ? null
        : _apartments.reduce((a, b) => a.rent >= b.rent ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kira artış hesaplayıcısı',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedId,
                    decoration: const InputDecoration(labelText: 'Daire seç'),
                    items: _apartments
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} · ${a.tenant}'),
                          ),
                        )
                        .toList(),
                    onChanged: _selectApartment,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _rentController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Mevcut kira tutarı',
                      suffixText: '₺',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateRent,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Zam oranı: %${_percent.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _percent,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '%${_percent.round()}',
                    onChanged: (v) => setState(() => _percent = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yeni kira',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        money(newRent),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (selected != null)
                    Text(
                      'Hesaplama tutarı: ${money(_currentRent)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Eğlenceli bilgiler',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _StatCard(
            icon: Icons.apartment,
            label: 'Portföyündeki daire sayısı',
            value: '${_apartments.length} daire',
            color: Colors.blue,
          ),
          _StatCard(
            icon: Icons.savings_outlined,
            label: 'Mevcut kiralara göre aylık toplam',
            value: money(total),
            color: Colors.green,
          ),
          _StatCard(
            icon: Icons.functions,
            label: 'Daire başına ortalama kira',
            value: money(average),
            color: Colors.deepPurple,
          ),
          _StatCard(
            icon: Icons.emoji_events_outlined,
            label: 'En yüksek kira',
            value: highest == null
                ? 'Henüz veri yok'
                : '${highest.name} · ${money(highest.rent)}',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          title: Text(label, style: const TextStyle(fontSize: 12)),
          subtitle: Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      );
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
