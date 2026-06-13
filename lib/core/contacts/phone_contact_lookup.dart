import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class PhoneContactMatch {
  const PhoneContactMatch({
    required this.name,
    required this.phone,
    required this.address,
  });

  final String name;
  final String phone;
  final String address;
}

enum PhoneContactAccessStatus {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
  failed,
}

class PhoneContactSearchResult {
  const PhoneContactSearchResult(this.status, {this.matches = const []});

  final PhoneContactAccessStatus status;
  final List<PhoneContactMatch> matches;
}

class PhoneContactLookup {
  const PhoneContactLookup();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<PhoneContactAccessStatus> checkPermission() async {
    if (!isSupported) return PhoneContactAccessStatus.unsupported;

    try {
      return _mapPermissionStatus(
        await FlutterContacts.permissions.check(PermissionType.read),
      );
    } catch (_) {
      return PhoneContactAccessStatus.failed;
    }
  }

  Future<PhoneContactAccessStatus> requestPermission() async {
    if (!isSupported) return PhoneContactAccessStatus.unsupported;

    try {
      return _mapPermissionStatus(
        await FlutterContacts.permissions.request(PermissionType.read),
      );
    } catch (_) {
      return PhoneContactAccessStatus.failed;
    }
  }

  Future<void> openSettings() async {
    if (!isSupported) return;
    await FlutterContacts.permissions.openSettings();
  }

  Future<PhoneContactSearchResult> searchByPhone(String phone) async {
    if (!isSupported) {
      return const PhoneContactSearchResult(
        PhoneContactAccessStatus.unsupported,
      );
    }

    final query = normalizePhoneNumber(phone);
    if (query.length < 3) {
      return const PhoneContactSearchResult(
        PhoneContactAccessStatus.granted,
      );
    }

    final permission = await checkPermission();
    if (permission != PhoneContactAccessStatus.granted) {
      return PhoneContactSearchResult(permission);
    }

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.address,
        },
        filter: ContactFilter.phone(phone),
      );
      final matches = <PhoneContactMatch>[];
      final matchedNumbers = <String>{};

      for (final contact in contacts) {
        for (final contactPhone in contact.phones) {
          if (!phoneNumberContainsQuery(contactPhone.number, query)) continue;
          final normalizedPhone = normalizePhoneNumber(contactPhone.number);
          if (!matchedNumbers.add(normalizedPhone)) continue;

          matches.add(
            PhoneContactMatch(
              name: contact.displayName?.trim() ?? '',
              phone: contactPhone.number.trim(),
              address: contact.addresses.isEmpty
                  ? ''
                  : contact.addresses.first.formatted?.trim() ?? '',
            ),
          );
          if (matches.length == 20) break;
        }
        if (matches.length == 20) break;
      }

      return PhoneContactSearchResult(
        PhoneContactAccessStatus.granted,
        matches: matches,
      );
    } catch (_) {
      return const PhoneContactSearchResult(
        PhoneContactAccessStatus.failed,
      );
    }
  }

  PhoneContactAccessStatus _mapPermissionStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited =>
        PhoneContactAccessStatus.granted,
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted =>
        PhoneContactAccessStatus.permanentlyDenied,
      PermissionStatus.denied ||
      PermissionStatus.notDetermined =>
        PhoneContactAccessStatus.denied,
    };
  }
}

String normalizePhoneNumber(String phone) {
  return phone.replaceAll(RegExp(r'\D'), '');
}

bool phoneNumbersMatch(String first, String second) {
  final normalizedFirst = normalizePhoneNumber(first);
  final normalizedSecond = normalizePhoneNumber(second);
  if (normalizedFirst.isEmpty || normalizedSecond.isEmpty) return false;
  if (normalizedFirst == normalizedSecond) return true;

  const localNumberLength = 10;
  if (normalizedFirst.length < localNumberLength ||
      normalizedSecond.length < localNumberLength) {
    return false;
  }

  return normalizedFirst
          .substring(normalizedFirst.length - localNumberLength) ==
      normalizedSecond.substring(normalizedSecond.length - localNumberLength);
}

bool phoneNumberContainsQuery(String phone, String query) {
  final normalizedPhone = normalizePhoneNumber(phone);
  final normalizedQuery = normalizePhoneNumber(query);
  return normalizedQuery.isNotEmpty &&
      normalizedPhone.contains(normalizedQuery);
}
