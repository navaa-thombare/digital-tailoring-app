class UnitWorkAssignmentTransition {
  const UnitWorkAssignmentTransition({
    required this.assignedWorkerByUnit,
    required this.unitStatusByUnit,
    required this.workerPaymentStatusByUnit,
    required this.walletDeltas,
  });

  final Map<int, String> assignedWorkerByUnit;
  final Map<int, String> unitStatusByUnit;
  final Map<int, String> workerPaymentStatusByUnit;
  final Map<String, int> walletDeltas;
}

bool canAssignOrderUnit({
  required String currentStatus,
  required String? assignedWorkerMobile,
}) {
  return assignedWorkerMobile != null || currentStatus == 'Measurements';
}

UnitWorkAssignmentTransition assignOrderUnit({
  required int unitIndex,
  required String defaultStatus,
  required String nextStatus,
  required String nextWorkerMobile,
  required int makerCharges,
  required Map<int, String> assignedWorkerByUnit,
  required Map<int, String> unitStatusByUnit,
  required Map<int, String> workerPaymentStatusByUnit,
}) {
  final previousWorkerMobile = assignedWorkerByUnit[unitIndex];
  final previousStatus = unitStatusByUnit[unitIndex] ?? defaultStatus;
  final wasReady = previousStatus == 'Ready';
  final becomesReady = nextStatus == 'Ready';
  final workerChanged = previousWorkerMobile != nextWorkerMobile;
  final statusChanged = previousStatus != nextStatus;

  final nextAssignments = Map<int, String>.of(assignedWorkerByUnit)
    ..[unitIndex] = nextWorkerMobile;
  final nextStatuses = Map<int, String>.of(unitStatusByUnit)
    ..[unitIndex] = nextStatus;
  final nextPaymentStatuses = Map<int, String>.of(workerPaymentStatusByUnit);
  if (workerChanged || statusChanged) {
    nextPaymentStatuses.remove(unitIndex);
  }

  final walletDeltas = <String, int>{};
  if (wasReady &&
      previousWorkerMobile != null &&
      (!becomesReady || workerChanged)) {
    walletDeltas.update(
      previousWorkerMobile,
      (amount) => amount - makerCharges,
      ifAbsent: () => -makerCharges,
    );
  }
  if (becomesReady && (!wasReady || workerChanged)) {
    walletDeltas.update(
      nextWorkerMobile,
      (amount) => amount + makerCharges,
      ifAbsent: () => makerCharges,
    );
  }

  return UnitWorkAssignmentTransition(
    assignedWorkerByUnit: nextAssignments,
    unitStatusByUnit: nextStatuses,
    workerPaymentStatusByUnit: nextPaymentStatuses,
    walletDeltas: walletDeltas,
  );
}
