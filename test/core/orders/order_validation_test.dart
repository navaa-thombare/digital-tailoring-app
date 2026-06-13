import 'package:flutter_test/flutter_test.dart';
import 'package:storemanagement/core/orders/order_validation.dart';

void main() {
  group('order creation validation', () {
    test('requires customer selection first', () {
      expect(
        validateOrderCreation(
          hasCustomer: false,
          templatesHaveMeasurements: const [true],
          deliveryDate: DateTime(2026, 6, 20),
        ),
        OrderCreationValidation.customerRequired,
      );
    });

    test('requires at least one template', () {
      expect(
        validateOrderCreation(
          hasCustomer: true,
          templatesHaveMeasurements: const [],
          deliveryDate: DateTime(2026, 6, 20),
        ),
        OrderCreationValidation.templateRequired,
      );
    });

    test('requires measurements for every template', () {
      expect(
        validateOrderCreation(
          hasCustomer: true,
          templatesHaveMeasurements: const [true, false],
          deliveryDate: DateTime(2026, 6, 20),
        ),
        OrderCreationValidation.measurementsRequired,
      );
    });

    test('requires delivery date', () {
      expect(
        validateOrderCreation(
          hasCustomer: true,
          templatesHaveMeasurements: const [true],
          deliveryDate: null,
        ),
        OrderCreationValidation.deliveryDateRequired,
      );
    });
  });

  group('delivery validation', () {
    test('delivers when every unit is ready and balance is nil', () {
      expect(
        deliveryOutcome(
          allTemplatesReady: true,
          balance: 0,
          promiseNote: '',
          promiseDate: null,
        ),
        DeliveryOutcome.delivered,
      );
    });

    test('uses DWP only with ready templates, note, and promise date', () {
      expect(
        deliveryOutcome(
          allTemplatesReady: true,
          balance: 500,
          promiseNote: 'Pay next week',
          promiseDate: DateTime(2026, 6, 20),
        ),
        DeliveryOutcome.dwp,
      );
    });

    test('blocks DWP without promise date', () {
      expect(
        deliveryOutcome(
          allTemplatesReady: true,
          balance: 500,
          promiseNote: 'Pay next week',
          promiseDate: null,
        ),
        DeliveryOutcome.blocked,
      );
    });

    test('blocks delivery while any template unit is not ready', () {
      expect(
        deliveryOutcome(
          allTemplatesReady: false,
          balance: 0,
          promiseNote: 'Pay next week',
          promiseDate: DateTime(2026, 6, 20),
        ),
        DeliveryOutcome.blocked,
      );
    });
  });
}
