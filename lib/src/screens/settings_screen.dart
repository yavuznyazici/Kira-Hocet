import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.fontScale, required this.rowHeight, required this.monthWidth, required this.onChanged});
  final double fontScale, rowHeight, monthWidth;
  final void Function({double? fontScale, double? rowHeight, double? monthWidth}) onChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Text('Ana ekran görünümü', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      _SettingSlider(title: 'Yazı büyüklüğü', value: fontScale, min: .8, max: 1.3, divisions: 10, display: '${(fontScale * 100).round()}%', onChanged: (v) => onChanged(fontScale: v)),
      _SettingSlider(title: 'Daire satır yüksekliği', value: rowHeight, min: 58, max: 110, divisions: 13, display: '${rowHeight.round()} px', onChanged: (v) => onChanged(rowHeight: v)),
      _SettingSlider(title: 'Ay sütun genişliği', value: monthWidth, min: 76, max: 130, divisions: 13, display: '${monthWidth.round()} px', onChanged: (v) => onChanged(monthWidth: v)),
      const SizedBox(height: 12),
      Card(child: const ListTile(
        leading: Icon(Icons.phone_android),
        title: Text('Veri saklama'),
        subtitle: Text('Kayıtlar bu cihazda, yerel SQLite veritabanında tutulur. Bulut yedekleme bu sürümde bulunmaz.'),
      )),
    ]),
  );
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({required this.title, required this.value, required this.min, required this.max, required this.divisions, required this.display, required this.onChanged});
  final String title, display; final double value, min, max; final int divisions; final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Text(display, style: TextStyle(color: Colors.blue.shade700))]),
    Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    const SizedBox(height: 10),
  ]);
}
