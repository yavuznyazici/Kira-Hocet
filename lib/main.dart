import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/data/app_database.dart';
import 'src/models/apartment.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/statistics_screen.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await AppDatabase.instance.database;
  runApp(const KiraHocetApp());
}

class KiraHocetApp extends StatefulWidget {
  const KiraHocetApp({super.key});

  @override
  State<KiraHocetApp> createState() => _KiraHocetAppState();
}

class _KiraHocetAppState extends State<KiraHocetApp> {
  int _tab = 0;
  double _fontScale = 1;
  double _rowHeight = 76;
  double _monthWidth = 90;

  void _updateSettings({double? fontScale, double? rowHeight, double? monthWidth}) {
    setState(() {
      _fontScale = fontScale ?? _fontScale;
      _rowHeight = rowHeight ?? _rowHeight;
      _monthWidth = monthWidth ?? _monthWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(fontScale: _fontScale, rowHeight: _rowHeight, monthWidth: _monthWidth),
      const StatisticsScreen(),
      SettingsScreen(
        fontScale: _fontScale,
        rowHeight: _rowHeight,
        monthWidth: _monthWidth,
        onChanged: _updateSettings,
      ),
    ];
    return MaterialApp(
      title: 'Kira Hoçet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_fontScale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana sayfa'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'İstatistikler'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Ayarlar'),
          ],
        ),
      ),
    );
  }
}
