import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
String money(num value) => _currency.format(value);
String monthLabel(DateTime date) => DateFormat('MMM yyyy', 'tr_TR').format(date);
