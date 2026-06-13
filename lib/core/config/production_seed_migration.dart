const currentTailoringStateSchema = 2;

const _legacyCustomerPhones = {'9876543410', '9988776655'};
const _legacyOrderIds = {'ORD-1042', 'ORD-1041'};
const _legacyTemplateNames = {'Men Shirt', 'Kurti'};
const _legacyWorkerMobiles = {
  '9876501111',
  '9876502222',
  '9876503333',
  '9876504444',
};

Map<String, dynamic> migrateLegacyProductionSeed(
  Map<String, dynamic> payload, {
  required bool isProduction,
}) {
  final schema = (payload['schema'] as num?)?.toInt() ?? 1;
  if (!isProduction || schema >= currentTailoringStateSchema) return payload;

  return {
    ...payload,
    'schema': currentTailoringStateSchema,
    'customers': _withoutLegacyValues(
      payload['customers'],
      key: 'phone',
      values: _legacyCustomerPhones,
    ),
    'orders': _withoutLegacyValues(
      payload['orders'],
      key: 'id',
      values: _legacyOrderIds,
    ),
    'templates': _withoutLegacyValues(
      payload['templates'],
      key: 'name',
      values: _legacyTemplateNames,
    ),
    'workers': _withoutLegacyValues(
      payload['workers'],
      key: 'mobile',
      values: _legacyWorkerMobiles,
    ),
  };
}

List<dynamic> _withoutLegacyValues(
  Object? source, {
  required String key,
  required Set<String> values,
}) {
  return [
    for (final raw in source as List? ?? const [])
      if (!values.contains((raw as Map)[key])) raw,
  ];
}
