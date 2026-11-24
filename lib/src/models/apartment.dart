class Apartment {
  const Apartment({
    this.id,
    required this.name,
    required this.tenant,
    required this.rent,
    required this.paymentDay,
    this.increaseRent,
    this.increaseMonth,
    this.increaseYear,
  });

  final int? id;
  final String name;
  final String tenant;
  final int rent;
  final int paymentDay;
  final int? increaseRent;
  final int? increaseMonth;
  final int? increaseYear;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'tenant': tenant,
        'rent': rent,
        'payment_day': paymentDay,
        'increase_rent': increaseRent,
        'increase_month': increaseMonth,
        'increase_year': increaseYear,
      };

  factory Apartment.fromMap(Map<String, Object?> map) => Apartment(
        id: map['id'] as int?,
        name: map['name'] as String,
        tenant: map['tenant'] as String,
        rent: map['rent'] as int,
        paymentDay: map['payment_day'] as int,
        increaseRent: map['increase_rent'] as int?,
        increaseMonth: map['increase_month'] as int?,
        increaseYear: map['increase_year'] as int?,
      );

  int rentFor(DateTime month) {
    if (increaseMonth == null || increaseYear == null || increaseRent == null) return rent;
    final effective = DateTime(increaseYear!, increaseMonth!);
    return !DateTime(month.year, month.month).isBefore(effective) ? increaseRent! : rent;
  }

  bool get hasScheduledIncrease => increaseMonth != null && increaseYear != null;
}
