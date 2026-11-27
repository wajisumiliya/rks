import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hasani_payroll_portal/services/login_habitat_scene.dart';

void main() {
  test('all 28 habitat images are included in the application asset bundle',
      () async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      for (final period in ['morning', 'afternoon', 'evening', 'night']) {
        final data =
            await rootBundle.load(LoginHabitatScene(weekday, period).asset);
        expect(data.lengthInBytes, greaterThan(8));
        expect(data.getUint32(0), 0x89504e47); // PNG signature
      }
    }
  });

  test(
      'Malaysia weekday and all four daily boundaries are independent of device timezone',
      () {
    final cases = {
      '2026-10-22T21:59:59Z': 'night', // Friday 05:59:59 MYT
      '2026-10-22T22:00:00Z': 'morning',
      '2026-10-23T03:59:59Z': 'morning',
      '2026-10-23T04:00:00Z': 'afternoon',
      '2026-10-23T08:59:59Z': 'afternoon',
      '2026-10-23T09:00:00Z': 'evening',
      '2026-10-23T11:59:59Z': 'evening',
      '2026-10-23T12:00:00Z': 'night',
    };
    for (final entry in cases.entries) {
      final scene = loginHabitatScene(instant: DateTime.parse(entry.key));
      expect(scene.period, entry.value);
      expect(scene.weekday, DateTime.friday);
    }
    expect(
        loginHabitatScene(instant: DateTime.parse('2026-10-23T16:00:00Z'))
            .weekday,
        DateTime.saturday);
  });

  test('the seven days and four periods select 28 distinct assets', () {
    final assets = <String>{};
    for (var day = 0; day < 7; day++) {
      for (final utcHour in [0, 5, 10, 13]) {
        final scene = loginHabitatScene(
            instant: DateTime.utc(2026, 10, 19 + day, utcHour));
        assets.add(scene.asset);
      }
    }
    expect(assets.length, 28);
    expect(assets, contains('assets/login_habitats/friday_evening.png'));
    expect(assets, contains('assets/login_habitats/sunday_night.png'));
  });
}
