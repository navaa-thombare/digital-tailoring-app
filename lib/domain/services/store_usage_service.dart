import '../../core/utils/app_date_utils.dart';
import '../../data/repositories/store_usage_repository.dart';

class StoreUsageService {
  StoreUsageService({StoreUsageRepository? repository})
      : _repository = repository ?? StoreUsageRepository();

  final StoreUsageRepository _repository;

  Future<void> decrementUsageDaysIfNeeded() async {
    final today = AppDateUtils.todayIsoDate();
    final limits = await _repository.activeUnexpiredLimits();
    for (final limit in limits) {
      final lastDate = limit['last_usage_decrement_date'] as String? ??
          limit['usage_start_date'] as String;
      final daysPassed = AppDateUtils.daysBetweenIsoDates(lastDate, today);
      if (daysPassed <= 0) continue;
      await _repository.applyDailyDecrement(
        usageLimitId: limit['id'] as String,
        storeId: limit['store_id'] as String,
        remainingDays: limit['remaining_usage_days'] as int,
        daysPassed: daysPassed,
        today: today,
      );
    }
  }
}
