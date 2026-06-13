import 'package:flutter_test/flutter_test.dart';
import 'package:storemanagement/core/contacts/phone_contact_lookup.dart';

void main() {
  test('normalizes formatted phone numbers', () {
    expect(normalizePhoneNumber('+91 98765-43210'), '919876543210');
  });

  test('matches local and country-code versions of a phone number', () {
    expect(phoneNumbersMatch('9876543210', '+91 98765 43210'), isTrue);
  });

  test('does not suffix-match short phone numbers', () {
    expect(phoneNumbersMatch('543210', '+91 98765 43210'), isFalse);
  });

  test('finds a partial number inside a formatted contact number', () {
    expect(phoneNumberContainsQuery('+91 98765-43210', '7654'), isTrue);
  });
}
