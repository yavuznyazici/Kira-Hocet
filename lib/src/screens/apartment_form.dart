import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/apartment.dart';

class ApartmentForm extends StatefulWidget {
  const ApartmentForm({super.key, this.apartment});
  final Apartment? apartment;

  @override
  State<ApartmentForm> createState() => _ApartmentFormState();
}

class _ApartmentFormState extends State<ApartmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tenant;
  late final TextEditingController _rent;
  late final TextEditingController _day;
  late final TextEditingController _increaseRent;
  late int _increaseMonth;
  late int _increaseYear;
  late bool _planIncrease;

  @override
  void initState() {
    super.initState();
    final a = widget.apartment;
    _name = TextEditingController(text: a?.name ?? '');
    _tenant = TextEditingController(text: a?.tenant ?? '');
    _rent = TextEditingController(text: a?.rent.toString() ?? '');
    _day = TextEditingController(text: a?.paymentDay.toString() ?? '1');
    _increaseRent = TextEditingController(text: a?.increaseRent?.toString() ?? '');
    _planIncrease = a?.increaseMonth != null && a?.increaseYear != null;
    _increaseMonth = a?.increaseMonth ?? DateTime.now().month;
    _increaseYear = a?.increaseYear ?? DateTime.now().year;
  }

  @override
  void dispose() {
    _name.dispose(); _tenant.dispose(); _rent.dispose(); _day.dispose(); _increaseRent.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Bu alan zorunludur' : null;
  int? _number(String value) => int.tryParse(value.replaceAll('.', '').replaceAll(',', ''));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final apartment = Apartment(
      id: widget.apartment?.id,
      name: _name.text.trim(),
      tenant: _tenant.text.trim(),
      rent: _number(_rent.text)!,
      paymentDay: _number(_day.text)!,
      increaseRent: _increaseRent.text.trim().isEmpty ? null : _number(_increaseRent.text),
      increaseMonth: _planIncrease ? _increaseMonth : null,
      increaseYear: _planIncrease ? _increaseYear : null,
    );
    await AppDatabase.instance.saveApartment(apartment.toMap());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.apartment == null ? 'Daire ekle' : 'Daireyi düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Daire adı'), validator: _required),
          const SizedBox(height: 12),
          TextFormField(controller: _tenant, decoration: const InputDecoration(labelText: 'Kiracı adı'), validator: _required),
          const SizedBox(height: 12),
          TextFormField(controller: _rent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mevcut kira (TL)'), validator: (v) => _number(v ?? '') == null || _number(v ?? '')! <= 0 ? 'Geçerli bir tutar girin' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _day, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kira ödeme günü (1-31)'), validator: (v) { final n = _number(v ?? ''); return n == null || n < 1 || n > 31 ? '1 ile 31 arasında bir gün girin' : null; }),
          const SizedBox(height: 22),
          Text('Planlanan kira artışı', style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _planIncrease,
            title: const Text('Zam başlangıç tarihini planla'),
            subtitle: const Text('Yeni tutar henüz belli değilse daha sonra girebilirsin.'),
            onChanged: (v) => setState(() => _planIncrease = v ?? false),
          ),
          if (_planIncrease) ...[
          const SizedBox(height: 8),
          TextFormField(controller: _increaseRent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Zamlı kira (TL) - isteğe bağlı'), validator: (v) => v != null && v.trim().isNotEmpty && (_number(v) == null || _number(v)! <= 0) ? 'Geçerli bir tutar girin' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: _increaseMonth,
              decoration: const InputDecoration(labelText: 'Başlangıç ayı'),
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'][i]))),
              onChanged: (v) => setState(() => _increaseMonth = v ?? _increaseMonth),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<int>(
              value: _increaseYear,
              decoration: const InputDecoration(labelText: 'Yıl'),
              items: List.generate(8, (i) { final y = DateTime.now().year - 1 + i; return DropdownMenuItem(value: y, child: Text('$y')); }),
              onChanged: (v) => setState(() => _increaseYear = v ?? _increaseYear),
            )),
          ]),
          ],
          const SizedBox(height: 28),
          FilledButton(onPressed: _save, child: const Text('Kaydet')),
          if (widget.apartment != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                  title: const Text('Daire silinsin mi?'),
                  content: const Text('Bu daireye ait ödeme geçmişi de silinir.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil'))],
                ));
                if (yes == true && widget.apartment?.id != null) {
                  await AppDatabase.instance.deleteApartment(widget.apartment!.id!);
                  if (context.mounted) Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.delete_outline), label: const Text('Daireyi sil'),
            ),
          ],
        ]),
      ),
    );
  }
}
