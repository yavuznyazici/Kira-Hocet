import 'package:flutter_test/flutter_test.dart';
import 'package:kira_hocet/src/models/apartment.dart';

void main() {
  test('planned rent increase applies from selected month only', () {
    const apartment = Apartment(
      name: 'Daire 1',
      tenant: 'Kiracı',
      rent: 10000,
      paymentDay: 5,
      increaseRent: 12500,
      increaseMonth: 1,
      increaseYear: 2027,
    );
    expect(apartment.rentFor(DateTime(2026, 12)), 10000);
    expect(apartment.rentFor(DateTime(2027, 1)), 12500);
    expect(apartment.rentFor(DateTime(2027, 5)), 12500);
  });

  test('no planned increase keeps current rent', () {
    const apartment = Apartment(name: 'Daire', tenant: 'Kiracı', rent: 8000, paymentDay: 1);
    expect(apartment.rentFor(DateTime(2027, 1)), 8000);
  });
}
