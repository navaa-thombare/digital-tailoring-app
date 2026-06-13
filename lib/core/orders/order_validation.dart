enum OrderCreationValidation {
  valid,
  customerRequired,
  templateRequired,
  measurementsRequired,
  deliveryDateRequired,
}

OrderCreationValidation validateOrderCreation({
  required bool hasCustomer,
  required List<bool> templatesHaveMeasurements,
  required DateTime? deliveryDate,
}) {
  if (!hasCustomer) return OrderCreationValidation.customerRequired;
  if (templatesHaveMeasurements.isEmpty) {
    return OrderCreationValidation.templateRequired;
  }
  if (templatesHaveMeasurements.any((hasMeasurements) => !hasMeasurements)) {
    return OrderCreationValidation.measurementsRequired;
  }
  if (deliveryDate == null) {
    return OrderCreationValidation.deliveryDateRequired;
  }
  return OrderCreationValidation.valid;
}

enum DeliveryOutcome { blocked, delivered, dwp }

DeliveryOutcome deliveryOutcome({
  required bool allTemplatesReady,
  required int balance,
  required String promiseNote,
  required DateTime? promiseDate,
}) {
  if (!allTemplatesReady) return DeliveryOutcome.blocked;
  if (balance <= 0) return DeliveryOutcome.delivered;
  if (promiseNote.trim().isNotEmpty && promiseDate != null) {
    return DeliveryOutcome.dwp;
  }
  return DeliveryOutcome.blocked;
}
