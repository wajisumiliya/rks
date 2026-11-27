/// Malaysia has a fixed UTC+8 offset and does not observe daylight saving time.
DateTime malaysiaTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

class LoginHabitatScene {
  const LoginHabitatScene(this.weekday, this.period);
  final int weekday;
  final String period;
  static const days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  String get asset => 'assets/login_habitats/${days[weekday - 1]}_$period.png';
}

LoginHabitatScene loginHabitatScene({
  required DateTime instant,
  int? previewWeekday,
}) {
  final local = malaysiaTime(instant);
  final period = local.hour < 6 || local.hour >= 20
      ? 'night'
      : local.hour < 12
          ? 'morning'
          : local.hour < 17
              ? 'afternoon'
              : 'evening';
  return LoginHabitatScene(previewWeekday ?? local.weekday, period);
}
