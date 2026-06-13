import 'package:flutter_test/flutter_test.dart';
import 'package:storemanagement/core/orders/unit_work_assignment.dart';

void main() {
  test('new assignment is allowed only from Measurements status', () {
    expect(
      canAssignOrderUnit(
        currentStatus: 'Measurements',
        assignedWorkerMobile: null,
      ),
      isTrue,
    );
    expect(
      canAssignOrderUnit(
        currentStatus: 'Ready',
        assignedWorkerMobile: null,
      ),
      isFalse,
    );
  });

  test('assigning one unit does not assign or update another unit', () {
    final transition = assignOrderUnit(
      unitIndex: 0,
      defaultStatus: 'Measurements',
      nextStatus: 'In Stitching',
      nextWorkerMobile: 'worker-1',
      makerCharges: 250,
      assignedWorkerByUnit: const {},
      unitStatusByUnit: const {},
      workerPaymentStatusByUnit: const {},
    );

    expect(transition.assignedWorkerByUnit, {0: 'worker-1'});
    expect(transition.unitStatusByUnit, {0: 'In Stitching'});
    expect(transition.assignedWorkerByUnit[1], isNull);
    expect(transition.unitStatusByUnit[1], isNull);
    expect(transition.walletDeltas, isEmpty);
  });

  test('different quantity units can be assigned to different workers', () {
    final first = assignOrderUnit(
      unitIndex: 0,
      defaultStatus: 'Measurements',
      nextStatus: 'In Stitching',
      nextWorkerMobile: 'worker-1',
      makerCharges: 250,
      assignedWorkerByUnit: const {},
      unitStatusByUnit: const {},
      workerPaymentStatusByUnit: const {},
    );
    final second = assignOrderUnit(
      unitIndex: 1,
      defaultStatus: 'Measurements',
      nextStatus: 'In Stitching',
      nextWorkerMobile: 'worker-2',
      makerCharges: 250,
      assignedWorkerByUnit: first.assignedWorkerByUnit,
      unitStatusByUnit: first.unitStatusByUnit,
      workerPaymentStatusByUnit: first.workerPaymentStatusByUnit,
    );

    expect(second.assignedWorkerByUnit, {
      0: 'worker-1',
      1: 'worker-2',
    });
  });

  test('maker charge is credited once when the selected unit becomes ready',
      () {
    final ready = assignOrderUnit(
      unitIndex: 0,
      defaultStatus: 'Measurements',
      nextStatus: 'Ready',
      nextWorkerMobile: 'worker-1',
      makerCharges: 250,
      assignedWorkerByUnit: const {0: 'worker-1'},
      unitStatusByUnit: const {0: 'In Stitching'},
      workerPaymentStatusByUnit: const {},
    );
    final unchangedReady = assignOrderUnit(
      unitIndex: 0,
      defaultStatus: 'Measurements',
      nextStatus: 'Ready',
      nextWorkerMobile: 'worker-1',
      makerCharges: 250,
      assignedWorkerByUnit: ready.assignedWorkerByUnit,
      unitStatusByUnit: ready.unitStatusByUnit,
      workerPaymentStatusByUnit: ready.workerPaymentStatusByUnit,
    );

    expect(ready.walletDeltas, {'worker-1': 250});
    expect(unchangedReady.walletDeltas, isEmpty);
  });

  test('ready unit reassignment moves maker charge between workers', () {
    final transition = assignOrderUnit(
      unitIndex: 0,
      defaultStatus: 'Measurements',
      nextStatus: 'Ready',
      nextWorkerMobile: 'worker-2',
      makerCharges: 250,
      assignedWorkerByUnit: const {0: 'worker-1'},
      unitStatusByUnit: const {0: 'Ready'},
      workerPaymentStatusByUnit: const {0: 'Paid-Worker'},
    );

    expect(transition.walletDeltas, {
      'worker-1': -250,
      'worker-2': 250,
    });
    expect(transition.workerPaymentStatusByUnit[0], isNull);
  });

  test('moving a ready unit back to hold reverses its maker charge', () {
    final transition = assignOrderUnit(
      unitIndex: 1,
      defaultStatus: 'Measurements',
      nextStatus: 'Hold',
      nextWorkerMobile: 'worker-2',
      makerCharges: 250,
      assignedWorkerByUnit: const {0: 'worker-1', 1: 'worker-2'},
      unitStatusByUnit: const {0: 'Ready', 1: 'Ready'},
      workerPaymentStatusByUnit: const {},
    );

    expect(transition.walletDeltas, {'worker-2': -250});
    expect(transition.unitStatusByUnit, {0: 'Ready', 1: 'Hold'});
  });
}
