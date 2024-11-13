import 'dart:math';

import 'package:stardart/aspects.dart';
import 'package:stardart/houses.dart';
import 'package:test/test.dart';
import 'package:stardart/charts.dart';

const delta = 1e-6;

void main() {
  final Place defaultPlace = (name: 'Moscow', coords: Point(-37.58, 55.75));
  final settings = (
    houses: HouseSystem.placidus,
    trueNode: true,
    orbs: Orbs.dariot,
    aspectTypes: 0x1 // AspectType.major.value
  );
  group('Base Chart', () {
    final chart = BaseChart(
        name: 'Test Chart',
        djd: 23772.990277,
        place: defaultPlace,
        settings: settings);
    group('Smoke test', () {
      test('Houses', () => expect(chart.houses.length, equals(12)));
      test('Objects', () => expect(chart.objects.length, equals(11)));
      test('Aspects', () => expect(chart.aspects, isNotEmpty));
      test('AspectsTo', () {
        final aspects = chart.aspectsTo(ChartObjectType.jupiter);
        expect(aspects.length, equals(5));
      });
      test('Sphera', () => expect(chart.sphera, isNotNull));
      test('Points', () => expect(chart.points, isNotNull));
      test('Sidereal Time',
          () => expect(chart.siderealTime, closeTo(23.03702536997929, 1e-6)));
    });
  });

  group('Birth Chart', () {
    final chart = BirthChart(
        firstName: 'Joe',
        lastName: 'Doe',
        birthTime: DateTime.utc(1965, 2, 1, 11, 46),
        place: defaultPlace);
    test('djd', () => expect(chart.djd, closeTo(23772.990277, 1e-4)));
    test('name', () => expect(chart.name, equals("Birth Chart for Joe Doe")));
  });
}
